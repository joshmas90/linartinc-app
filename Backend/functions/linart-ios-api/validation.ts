export class APIError extends Error {
  status: number;
  constructor(status: number, message: string) { super(message); this.status = status; }
}
export const uuid = (value: unknown): value is string => typeof value === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
const object = (value: unknown): value is Record<string, unknown> => !!value && typeof value === "object" && !Array.isArray(value);
const text = (value: unknown, max: number) => typeof value === "string" && value.length <= max;
export function validatePayload(value: unknown) {
  if (!object(value) || !object(value.draft) || !Array.isArray(value.photos) || value.photos.length > 8) throw new APIError(400, "Invalid project brief.");
  const fields = ["inquiryEmail", "projectType", "goals", "existingConditions", "style", "priorities", "investment", "timeline", "constraints", "other"];
  for (const field of fields) if (!text(value.draft[field], 10000)) throw new APIError(400, "A project answer is missing or too long.");
  if (!Array.isArray(value.draft.references) || value.draft.references.length > 10 || !Array.isArray(value.draft.ideas) || value.draft.ideas.length > 50) throw new APIError(400, "Too many saved references.");
  for (const reference of value.draft.references) {
    if (!object(reference) || !uuid(reference.id) || !text(reference.url, 1000) || !text(reference.note, 2000)) throw new APIError(400, "Invalid reference.");
    let url: URL;
    try { url = new URL(reference.url as string); } catch { throw new APIError(400, "Invalid reference address."); }
    if (!["https:", "http:"].includes(url.protocol) || url.username || url.password) throw new APIError(400, "Invalid reference address.");
  }
  for (const idea of value.draft.ideas) if (!object(idea) || !text(idea.id, 120) || !text(idea.title, 200) || !text(idea.note, 10000)) throw new APIError(400, "Invalid saved idea.");
  const ids = new Set<string>();
  for (const photo of value.photos) {
    if (!object(photo) || !uuid(photo.id) || ids.has(photo.id) || !text(photo.purpose, 100) || !text(photo.note, 10000) ||
        typeof photo.sha256 !== "string" || !/^[a-f0-9]{64}$/.test(photo.sha256) || !Number.isInteger(photo.bytes) || Number(photo.bytes) < 1 || Number(photo.bytes) > 5000000) throw new APIError(400, "Invalid photo manifest.");
    ids.add(photo.id);
  }
  if (new TextEncoder().encode(JSON.stringify(value)).byteLength > 100000) throw new APIError(413, "This brief is too large. Export a PDF instead.");
  return value as { draft: Record<string, unknown>; photos: Array<{ id: string; purpose: string; note: string; sha256: string; bytes: number }> };
}
export async function digest(bytes: BufferSource) {
  return Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)), b => b.toString(16).padStart(2, "0")).join("");
}
export async function boundedBody(req: Request, maximum: number) {
  if (Number(req.headers.get("content-length")) > maximum) throw new APIError(413, "Upload is too large.");
  const reader = req.body?.getReader(); if (!reader) throw new APIError(400, "Missing request body.");
  const chunks: Uint8Array[] = []; let total = 0;
  while (true) {
    const { value, done } = await reader.read(); if (done) break;
    total += value.byteLength;
    if (total > maximum) { await reader.cancel(); throw new APIError(413, "Upload is too large."); }
    chunks.push(value);
  }
  const result = new Uint8Array(total); let offset = 0;
  for (const chunk of chunks) { result.set(chunk, offset); offset += chunk.length; }
  return result;
}
