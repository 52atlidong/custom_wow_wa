const fs = require('fs')

const str = fs.readFileSync('C:\\Users\\p.wang\\Downloads\\WindDungeonHelper-2.4.0\\WindDungeonHelper\\Modules\\AvoidableDamageData\\GrimBatol.lua', 'utf-8')

// const res = str.exec(/(spell|aura) = ([0-9]*)/g)

// const matches;

// const res = /(spell|aura) = ([0-9]*)/g.exec(str)

const reg = /(spell|aura) = ([0-9]*)/g

let matches;

// let spellIDs = []

let output = '{\n'

while((matches = reg.exec(str)) !== null) {
    // console.log(matches[2])

    // spellIDs.push(matches[2])

    output += `[${matches[2]}] = "",\n`

}

output += '}'

console.log(output)
