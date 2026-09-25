import { APIError, uuid, validatePayload, digest, boundedBody } from "./validation.ts";

const base = Deno.env.get("SUPABASE_URL")!;
const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const bucket = "linart-ios-studio";
const headers = { apikey: service, Authorization: `Bearer ${service}` };
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });
async function api(path: string, options: RequestInit = {}) {
  const response = await fetch(`${base}/${path}`, { ...options, headers: { ...headers, "Content-Type": "application/json", ...options.headers } });
  if (!response.ok) throw new APIError(response.status === 409 ? 409 : 503, "The service could not complete this request. Your local Studio is safe.");
  const body = await response.text(); return body ? JSON.parse(body) : null;
}
async function authenticate(req: Request) {
  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) throw new APIError(401, "Sign in to send your Studio.");
  const response = await fetch(`${base}/auth/v1/user`, { headers: { apikey: service, Authorization: authorization } });
  if (!response.ok) throw new APIError(401, "Please sign in again.");
  const user = await response.json();
  if (!uuid(user.id) || !user.email_confirmed_at || user.is_anonymous) throw new APIError(403, "Verify your email before sending.");
  // The token has already been verified by Auth. Check the live session as well.
  let claims;
  try { const segment = authorization.split(".")[1].replace(/-/g,"+").replace(/_/g,"/"); claims = JSON.parse(atob(segment)); } catch { throw new APIError(401, "Invalid session."); }
  if (!uuid(claims.session_id) || !await api("rest/v1/rpc/linart_ios_session_active", { method: "POST", body: JSON.stringify({ p_user: user.id, p_session: claims.session_id }) })) throw new APIError(401, "Your session has ended. Sign in again.");
  return user as { id: string; email: string };
}
async function owned(id: string, user: string) {
  if (!uuid(id)) throw new APIError(400, "Invalid submission reference.");
  const rows = await api(`rest/v1/linart_ios_submissions?id=eq.${id}&user_id=eq.${user}&select=*`);
  if (!rows?.length) throw new APIError(404, "Submission not found.");
  return rows[0];
}
Deno.serve(async req => {
  try {
    const user = await authenticate(req);
    const url = new URL(req.url);
    const action = url.searchParams.get("action");
    const id = url.searchParams.get("id") ?? "";
    if (req.method === "GET" && action === "receipts") {
      const rows = await api(`rest/v1/linart_ios_submissions?user_id=eq.${user.id}&select=id,submitted_at,status,created_at&order=created_at.desc&limit=100`);
      return json({ receipts: rows });
    }
    if (req.method === "POST" && action === "begin") {
      if (!uuid(id)) throw new APIError(400, "Invalid submission reference.");
      const bytes = await boundedBody(req, 100000);
      let input;
      try { input = JSON.parse(new TextDecoder().decode(bytes)); } catch { throw new APIError(400, "Invalid brief."); }
      const payload = validatePayload(input);
      const hash = await digest(bytes);
      const result = await api("rest/v1/rpc/linart_ios_begin", { method: "POST", body: JSON.stringify({ p_id:id, p_user:user.id, p_payload:payload, p_hash:hash }) });
      return json(result);
    }
    if (req.method === "PUT" && action === "photo") {
      const submission = await owned(id, user.id);
      if (submission.status !== "draft") throw new APIError(409, "This submission is already closed.");
      const photo = submission.payload.photos.find((photo: { id: string }) => photo.id === url.searchParams.get("photo"));
      if (!photo) throw new APIError(400, "Photo is not part of this brief.");
      if (req.headers.get("Content-Type") !== "image/jpeg") throw new APIError(415, "JPEG photos are required.");
      const bytes = await boundedBody(req, 5000000);
      if (bytes.length !== photo.bytes || bytes[0] !== 255 || bytes[1] !== 216 || bytes[2] !== 255 || await digest(bytes) !== photo.sha256) throw new APIError(400, "The photo did not match the prepared brief.");
      const path = `${user.id}/${id}/${photo.id}.jpg`;
      const uploaded = await fetch(`${base}/storage/v1/object/${bucket}/${path}`, { method: "POST", headers: { ...headers, "Content-Type": "image/jpeg", "x-upsert": "false" }, body: bytes });
      if (!uploaded.ok) {
        // A timeout may hide a successful upload. Accept a retry only after checking the stored bytes.
        const prior = await fetch(`${base}/storage/v1/object/authenticated/${bucket}/${path}`, { headers });
        if (!prior.ok || await digest(await prior.arrayBuffer()) !== photo.sha256) throw new APIError(503, "Photo upload could not be confirmed. Retry this submission.");
      }
      try {
        await api("rest/v1/linart_ios_attachments?on_conflict=submission_id,id", { method: "POST", headers: { Prefer: "resolution=ignore-duplicates" }, body: JSON.stringify({ submission_id: id, id: photo.id, object_path: path, byte_count: photo.bytes, sha256: photo.sha256 }) });
        const latest = await owned(id, user.id);
        if (latest.status === "deleting") throw new APIError(409, "This submission is being removed.");
      } catch (error) {
        await api(`storage/v1/object/${bucket}`, { method: "DELETE", body: JSON.stringify({ prefixes: [path] }) });
        throw error;
      }
      return json({ ok: true });
    }
    if (req.method === "POST" && action === "submit") {
      await owned(id, user.id);
      const receipt = await api("rest/v1/rpc/linart_ios_finalize", { method: "POST", body: JSON.stringify({ p_id: id, p_user: user.id }) });
      return json(receipt);
    }
    if (req.method === "DELETE" && action === "delete") {
      const submission = await owned(id, user.id);
      await api(`rest/v1/linart_ios_submissions?id=eq.${id}&user_id=eq.${user.id}`, { method: "PATCH", body: JSON.stringify({ status: "deleting" }) });
      const paths = submission.payload.photos.map((photo: { id: string }) => `${user.id}/${id}/${photo.id}.jpg`);
      if (paths.length) await api(`storage/v1/object/${bucket}`, { method: "DELETE", body: JSON.stringify({ prefixes: paths }) });
      await api(`rest/v1/linart_ios_submissions?id=eq.${id}&user_id=eq.${user.id}`, { method: "DELETE" });
      return json({ ok: true });
    }
    throw new APIError(405, "Unsupported request.");
  } catch (error) {
    if (error instanceof APIError) return json({ error: error.message }, error.status);
    // Never log tokens, emails, request bodies or photos.
    console.error("linart-ios-api: request failed");
    return json({ error: "The service is temporarily unavailable. Your local Studio is safe." }, 503);
  }
});
