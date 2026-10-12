const b64=bytes=>btoa(String.fromCharCode(...bytes)).replaceAll('+','-').replaceAll('/','_').replaceAll('=','');
export async function signPlayback({playbackId,keyId,privateKey,now,expiresAt}) {
 if(!/^[A-Za-z0-9]{1,255}$/.test(playbackId)||!/^[A-Za-z0-9_-]{1,255}$/.test(keyId)||!Number.isSafeInteger(now)||!Number.isSafeInteger(expiresAt)||expiresAt<=now) throw Error('INVALID_GRANT');
 const exp=Math.min(now+300,expiresAt);
 const encode=x=>b64(new TextEncoder().encode(JSON.stringify(x)));
 const data=encode({alg:'RS256',typ:'JWT'})+'.'+encode({sub:playbackId,aud:'v',kid:keyId,exp});
 const pem=privateKey.replace('-----BEGIN PRIVATE KEY-----','').replace('-----END PRIVATE KEY-----','').replaceAll(/\s/g,'');
 const key=await crypto.subtle.importKey('pkcs8',Uint8Array.from(atob(pem),c=>c.charCodeAt(0)),{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['sign']);
 return data+'.'+b64(new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5',key,new TextEncoder().encode(data))));
}
