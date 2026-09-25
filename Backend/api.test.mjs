import test from 'node:test';
import assert from 'node:assert/strict';
let handler;
globalThis.Deno = { env: { get: key => key === 'SUPABASE_URL' ? 'https://backend.invalid' : 'test-server-key' }, serve: value => { handler = value; } };
await import('./functions/linart-ios-api/index.ts');
const user = 'de305d54-75b4-431b-adb2-eb6b9e546014';
const session = 'de305d54-75b4-431b-adb2-eb6b9e546015';
const submission = 'de305d54-75b4-431b-adb2-eb6b9e546016';
const token = 'header.' + Buffer.from(JSON.stringify({session_id: session})).toString('base64url') + '.signature';
const response = (value, status=200) => new Response(JSON.stringify(value),{status});
function mock(entries) {
  const calls=[];
  globalThis.fetch=async(url, options={})=>{
    assert.equal(new URL(url).origin,'https://backend.invalid');
    calls.push({url,options});
    const next=entries.shift(); assert.ok(next,`Unexpected request ${url}`);
    assert.ok(url.includes(next[0]),`Expected ${next[0]}, got ${url}`);
    return response(next[1],next[2]??200);
  };
  return { calls, done:()=>assert.equal(entries.length,0) };
}
const auth = () => [['auth/v1/user',{id:user,email:'fixture@example.invalid',email_confirmed_at:'2026-01-01',is_anonymous:false}],['rpc/linart_ios_session_active',true]];
const request = (action, method='GET', body) => new Request(`https://edge.invalid?action=${action}&id=${submission}`,{method,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:body&&JSON.stringify(body)});
const brief = () => ({draft:{inquiryEmail:'',projectType:'',goals:'More light',existingConditions:'',style:'',priorities:'',investment:'',timeline:'',constraints:'',other:'',references:[],ideas:[]},photos:[]});

test('anonymous and revoked sessions cannot read receipts',async()=>{
  let m=mock([]); assert.equal((await handler(new Request('https://edge.invalid?action=receipts'))).status,401);m.done();
  m=mock([auth()[0],['rpc/linart_ios_session_active',false]]);
  assert.equal((await handler(request('receipts'))).status,401);m.done();
});
test('receipts are filtered to the verified user, ignoring forged query ownership',async()=>{
  const m=mock([...auth(),[`user_id=eq.${user}`,[]]]);
  const result=await handler(new Request(`https://edge.invalid?action=receipts&user_id=another`,{headers:{Authorization:`Bearer ${token}`}}));
  assert.equal(result.status,200);assert.deepEqual(await result.json(),{receipts:[]});m.done();
});
test('foreign submission cannot be deleted',async()=>{
  const m=mock([...auth(),[`id=eq.${submission}&user_id=eq.${user}`,[]]]);
  assert.equal((await handler(request('delete','DELETE'))).status,404);m.done();
});
test('quota errors become actionable 429 without leaking database errors',async()=>{
  const m=mock([...auth(),['rpc/linart_ios_begin',{message:'Submission limit reached. Remove unused app submissions or try tomorrow.'},400]]);
  const result=await handler(request('begin','POST',brief()));assert.equal(result.status,429);m.done();
});
test('requesting deletion removes only app uploads and records a stable request',async()=>{
  const row={id:submission,payload:{photos:[{id:session}]}};
  const m=mock([...auth(),['rpc/linart_ios_request_deletion',{id:session,requested_at:'2026-09-25'}],['linart_ios_submissions?user_id',[row]],['linart_ios_submissions?id',null],['storage/v1/object/linart-ios-studio',[]],['linart_ios_submissions?id',null],['linart_ios_deletion_requests?user_id',null]]);
  const result=await handler(request('account','DELETE'));assert.equal(result.status,200);
  const storage=m.calls.find(c=>c.url.includes('/storage/'));
  assert.deepEqual(JSON.parse(storage.options.body),{prefixes:[`${user}/${submission}/${session}.jpg`]});
  assert.equal(m.calls.some(c=>c.url.includes('auth/v1/admin')),false);
  assert.equal(m.calls.some(c=>c.url.includes('linart_inquiries')),false);m.done();
});
test('storage deletion failure preserves database reference and does not claim completion',async()=>{
  const row={id:submission,payload:{photos:[{id:session}]}};
  const m=mock([...auth(),['linart_ios_submissions?id',[row]],['linart_ios_submissions?id',null],['storage/v1/object/linart-ios-studio',{message:'fixture error'},500]]);
  assert.equal((await handler(request('delete','DELETE'))).status,503);m.done();
});
