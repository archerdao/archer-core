const NODE_DIR            = "./node_modules";
const README_FILE         = "./docs/README.md";
const SUMMARY_FILE        = "./docs/SUMMARY.md";
const EXCLUDE_FILE        = "./docs/exclude.txt";
const TEMPLATE_DIR        = "./docs/templates";
const PAGES_DIR           = "./docs/pages";
const CONTRACT_INPUT_DIR  = "./contracts";
const CONTRACT_OUTPUT_DIR = "./docs/pages/archer-core";


const fs         = require("fs");
const path       = require("path");
const { config } = require("hardhat");
const spawnSync  = require("child_process").spawnSync;

const relativePath = path.relative(path.dirname(SUMMARY_FILE), PAGES_DIR);

let excludeInputList = [] 
let excludeOutputList = []

if(fs.existsSync(EXCLUDE_FILE)) {
    excludeInputList = lines(EXCLUDE_FILE).map(line => CONTRACT_INPUT_DIR + "/" + line);
    excludeOutputList = lines(EXCLUDE_FILE).map(line => CONTRACT_OUTPUT_DIR + "/" + line);
}

function lines(pathName) {
    return fs.readFileSync(pathName, {encoding: "utf8"}).split("\r").join("").split("\n");
}

function formatTitle(title) {
    return title.replace(/\b\w/g, l => l.toUpperCase()).replace(/-|_/g, " ")
}

function scan(pathName, indentation) {
    if (!excludeInputList.includes(pathName)) {
        if (fs.lstatSync(pathName).isDirectory()) {
            if(fs.existsSync(pathName + "/README.md")) {
                const link = pathName.slice(PAGES_DIR.length) + "/README.md";
                fs.appendFileSync(SUMMARY_FILE, indentation + "* [" + formatTitle(path.basename(pathName)) + "](" + relativePath + link + ")\n");
            } else {
                fs.appendFileSync(SUMMARY_FILE, indentation + "* " + formatTitle(path.basename(pathName)) + "\n");
            }
            for (const fileName of fs.readdirSync(pathName))
                scan(pathName + "/" + fileName, indentation + "  ");
        }
        else if (pathName.endsWith(".md") && !pathName.endsWith("README.md")) {
            const text = formatTitle(path.basename(pathName).slice(0, -3));
            const link = pathName.slice(PAGES_DIR.length);
            fs.appendFileSync(SUMMARY_FILE, indentation + "* [" + text + "](" + relativePath + link + ")\n");
        }
    }
}

function fix(pathName) {
    if (!excludeOutputList.includes(pathName)) {
        if (fs.lstatSync(pathName).isDirectory()) {
            for (const fileName of fs.readdirSync(pathName))
                fix(pathName + "/" + fileName);
        }
        else if (pathName.endsWith(".md")) {
            fs.writeFileSync(pathName, lines(pathName).filter(line => line.trim().length > 0).join("\n\n") + "\n");
        }
    } else {
        if (fs.lstatSync(pathName).isDirectory()) {
            fs.rmdirSync(pathName, { recursive: true });
        } else {
            fs.unlinkSync(pathName);
        }
    }
}

console.log("Creating .gitbook.yaml file...")
fs.writeFileSync (".gitbook.yaml", "root: ./\n");
fs.appendFileSync(".gitbook.yaml", "structure:\n");
fs.appendFileSync(".gitbook.yaml", "  readme: " + README_FILE + "\n");
fs.appendFileSync(".gitbook.yaml", "  summary: " + SUMMARY_FILE + "\n");

console.log("Generating contract documentation...")
const args = [
    NODE_DIR + "/solidity-docgen/dist/cli.js",
    "--input="         + CONTRACT_INPUT_DIR,
    "--output="        + CONTRACT_OUTPUT_DIR,
    "--templates="     + TEMPLATE_DIR,
    "--solc-module="   + NODE_DIR + "/hardhat/node_modules/solc",
    "--solc-settings=" + JSON.stringify(config.solidity.compilers[0].settings)
];
const result = spawnSync("node", args, {stdio: ["inherit", "inherit", "pipe"]});
if (result.stderr.length > 0)
    throw new Error(result.stderr);

console.log("Cleaning up documentation...")
fix(PAGES_DIR);

console.log("Generating SUMMARY.md file (Table of Contents)...")
fs.writeFileSync (SUMMARY_FILE, "# Summary\n");
for (const fileName of fs.readdirSync(PAGES_DIR))
    scan(PAGES_DIR + "/" + fileName, "");

console.log("Documentation finalized.")