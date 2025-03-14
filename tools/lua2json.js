'use strict';

// const lua2Json = require('lua-json');
const fs = require('fs/promises')

const poisRegex = /MDT\.mapPOIs\[dungeonIndex\]\s*=\s*({[\s\S]*?};)/;

async function readDungeonLua(dst) {

  const str = await fs.readFile(dst, 'utf-8');

  const match = str.match(poisRegex);
  // console.log(match);

  if(match) {
    const poisStr = match[1];
    console.log(poisStr);
    const output = lua2Json.parse('return ' + poisStr);
    console.log(output);
  }

  // if(match) {
  //   console.log(match[1]);
  // } else {
  //   console.log('未找到匹配内容');
  // }

}

// function 

readDungeonLua('/Users/lushijie/Desktop/custom_git/MythicDungeonTools/TheWarWithin/DarkflameCleft.lua');