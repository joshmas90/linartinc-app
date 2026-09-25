import test from 'node:test';
import assert from 'node:assert/strict';
import { validatePayload, boundedBody, digest, uuid } from './functions/linart-ios-api/validation.ts';
const base = () => ({draft:{inquiryEmail:'owner@example.com',projectType:'Kitchen Remodeling',goals:'More light',existingConditions:'',style:'',priorities:'',investment:'',timeline:'',constraints:'',other:'',references:[],ideas:[]},photos:[]});
test('valid local draft can be submitted without photos',()=>assert.equal(validatePayload(base()).draft.goals,'More light'));
test('rejects too many or duplicate photos and invalid hashes',()=>{
  for(const count of [2,9]) {const p=base();p.photos=Array(count).fill({id:'de305d54-75b4-431b-adb2-eb6b9e546014',purpose:'My space',note:'',sha256:'a'.repeat(64),bytes:100});assert.throws(()=>validatePayload(p));}
  const p=base();p.photos=[{id:'de305d54-75b4-431b-adb2-eb6b9e546014',purpose:'My space',note:'',sha256:'bad',bytes:100}];assert.throws(()=>validatePayload(p));
});
test('rejects credential-bearing and executable links',()=>{
  for(const url of ['javascript:alert(1)','https://name:password@example.com']) {const p=base();p.draft.references=[{id:'de305d54-75b4-431b-adb2-eb6b9e546014',url,note:''}];assert.throws(()=>validatePayload(p));}
});
test('bounds strings and total request size',()=>{
  const p=base();p.draft.goals='x'.repeat(10001);assert.throws(()=>validatePayload(p));
  const extra=base();extra.unexpected='x'.repeat(100000);assert.throws(()=>validatePayload(extra));
});
test('bounded body rejects chunked uploads exceeding the limit',async()=>{
  const body=new ReadableStream({start(c){c.enqueue(new Uint8Array(4));c.enqueue(new Uint8Array(4));c.close();}});
  await assert.rejects(boundedBody(new Request('https://example.invalid',{method:'POST',body,duplex:'half'}),7));
});
test('hash matches standard SHA-256 and identifiers are restricted',async()=>{
  assert.equal(await digest(new TextEncoder().encode('abc')),'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  assert.equal(uuid('../other-user'),false);assert.equal(uuid('de305d54-75b4-431b-adb2-eb6b9e546014'),true);
});
