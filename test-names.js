// Runnable check for the leaderboard name filter. `node test-names.js`, no deps.
// Reads the regexes straight out of index.html so this file cannot drift from the game.
const fs=require('fs');
const src=fs.readFileSync(__dirname+'/index.html','utf8');
const pick=n=>{const m=src.match(new RegExp('^const '+n+'=(/.*/);$','m'));if(!m)throw new Error(n+' not found in index.html');return eval(m[1]);};
const NAME_BAN=pick('NAME_BAN'), NAME_BAN_EXACT=pick('NAME_BAN_EXACT');
const cleanName=s=>String(s||'').toUpperCase().replace(/[^A-Z0-9]/g,'').slice(0,6);
const nameAllowed=n=>!NAME_BAN.test(n)&&!NAME_BAN_EXACT.test(n);

const BLOCK=['fuck','FUCKU','xfuckx','shit','cunt','n i g g a','NIGGER','n1gga','faggy','kike',
  'chink','tranny','hitler','retard','whore','rape','nazi','fag','spic','coon','gook','twat','cum'];
// Ordinary names must survive - especially the ones that contain a banned word.
const ALLOW=['LOK','ABC123','GRAPE','BASS','SPICY','COONS','CRAPE','PASS','GLASS','ASS','DICK',
  'MIKE','RETRO','CHIN','FAGAN','CUMIN','SCUM','TIGER','CALM3','ZZZ999',
  // Known ceiling: cleanName STRIPS punctuation, so a deliberately mangled spelling gets through.
  // That is accepted - the admin panel deletes anything that does. Pinned here so it is a decision,
  // not a surprise, if someone later thinks the filter is airtight.
  'SH!TTY','F.C.K'];

let bad=0;
for(const s of BLOCK) if(nameAllowed(cleanName(s))){console.log('FAIL should block: '+s+' -> '+cleanName(s));bad++;}
for(const s of ALLOW) if(!nameAllowed(cleanName(s))){console.log('FAIL should allow: '+s+' -> '+cleanName(s));bad++;}
if(bad)process.exit(1);
console.log('name filter ok - '+BLOCK.length+' blocked, '+ALLOW.length+' allowed');
