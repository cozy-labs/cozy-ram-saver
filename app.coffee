#!/usr/bin/env coffee
fs = require 'fs-extra'
path = require 'path'
async = require 'async'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
exec = require('child_process').exec

appPath = process.argv[2]
console.log "Moving shared modules for #{appPath}"
sharedPath = '/usr/local/lib/node_shared_modules'

# FS based version
#listModules = (dir, moduleList) ->
#    moduleList ?= {}
#    files = fs.readdirSync dir
#    for file in files
#        if fs.statSync("#{dir}/#{file}").isDirectory() \
#        and file.charAt(0) isnt '.'
#
#            module = file
#            if fs.existsSync "#{dir}/#{module}/node_modules"
#                moduleList = listModules "#{dir}/#{module}/node_modules", moduleList
#
#            if fs.existsSync "#{dir}/#{module}/package.json"
#
#                version = require("#{dir}/#{module}/package.json").version
#
#                if (moduleList[module]? and moduleList[module][version]?) \
#                or fs.existsSync "#{sharedPath}/#{module}/#{version}"
#                    moduleList[module][version].shared = true
#                    moduleList[module][version].copies += 1
#
#                moduleList[module] ?= {}
#                moduleList[module][version] ?=
#                    shared: false,
#                    copies: 1,
#                    paths: []
#
#                moduleList[module][version].paths.push "#{dir}/#{module}"
#    return moduleList


# NPM list based version
exec "cd #{appPath} && npm list --json", (error, stdout, stderr) ->
    mainModule = JSON.parse stdout
    if not mainModule.problems

        listModules = (dep, path, moduleList) ->
            moduleList ?= {}
            path ?= appPath
            for moduleName, module of dep
                modulePath = "#{path}/node_modules/#{moduleName}"
                if module.dependencies?
                    moduleList = listModules module.dependencies, modulePath, moduleList
                if moduleList[moduleName]? \
                and moduleList[moduleName][module.version]?
                    moduleList[moduleName][module.version].shared = true
                    moduleList[moduleName][module.version].copies += 1

                moduleList[moduleName] ?= {}
                moduleList[moduleName][module.version] ?=
                    shared: false,
                    copies: 1,
                    paths: []

                moduleList[moduleName][module.version].paths.push modulePath

            return moduleList


        for module, versions of listModules mainModule.dependencies
            for version, info of versions
                if info.shared

                    # Sort path (deepest locations first)
                    info.paths.sort (pathA, pathB) ->
                        if pathA.split('/').length >= pathB.split('/').length
                            return -1
                        else
                            return 1

                    console.log module, version
                    sharedModulePath = "#{sharedPath}/#{module}"
                    mkdirp.sync sharedModulePath
                    if not fs.existsSync "#{sharedModulePath}/#{version}"
                        fs.copySync info.paths[0], "#{sharedModulePath}/#{version}"
                    for modulePath in info.paths
                    #async.eachSeries info.paths, (modPath, callback) ->
                        rimraf.sync modulePath
                        fs.symlinkSync "#{sharedModulePath}/#{version}", modulePath

        console.log 'Consolidating shared modules'
        exec "find #{sharedPath} -maxdepth 2 -type d | grep -E '^#{sharedPath}/(.*)/(.*)' | xargs -I folder npm --prefix folder install folder --production", (error, stdout, stderr) ->
            console.log stdout
