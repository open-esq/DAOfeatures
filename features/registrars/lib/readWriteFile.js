const fs = require("fs")
const path = require("path")

const storeData = (data, file) => {
  try {
    const directory = path.dirname(file)
    if (!fs.existsSync(directory)) {
      fs.mkdirSync(path.dirname(file))
    }

    fs.writeFileSync(file, JSON.stringify(data), { flag: "w" })
  } catch (err) {
    console.error(err)
  }
}

const loadData = path => {
  try {
    return fs.readFileSync(path, "utf8")
  } catch (err) {
    console.error(err)
    return false
  }
}

module.exports = {
  storeData,
  loadData,
}
