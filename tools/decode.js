
const fs = require('fs')
const zlib = require('zlib')

const mdtString = fs.readFileSync('./mdt.txt', 'utf-8');

const encodedString = mdtString.replace('!', "")

const binaryData = Buffer.from(encodedString, 'base64');

const decompressedData = zlib.inflateSync(binaryData);

const luaString = decompressedData.toString('utf-8');