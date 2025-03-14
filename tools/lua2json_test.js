
const parser = require('luaparse');

const fs = require('fs/promises');


async function main() {
  const dstPath = '/Users/lushijie/Desktop/custom_git/MythicDungeonTools/TheWarWithin/DarkflameCleft.lua';
  const luaStr = await fs.readFile(dstPath, 'utf-8');

  var ast = parser.parse(luaStr);

  // console.log(ast);

  const body = ast.body;

  

  for(var i = 0; i< body.length; i++) {
    // const content = body[i];
    // console.log(content);
  }

}

main();