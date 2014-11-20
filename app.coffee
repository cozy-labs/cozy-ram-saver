#!/usr/bin/env coffee
fs = require 'fs-extra'
path = require 'path'
async = require 'async'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
sh = require 'execSync'
exec = require('child_process').exec

appList =
    calendar:      '/usr/local/cozy/apps/calendar/calendar/cozy-agenda'
    contacts:      '/usr/local/cozy/apps/contacts/contacts/cozy-contacts'
    'data-system': '/usr/local/cozy/apps/data-system/data-system/cozy-data-system'
    files:         '/usr/local/cozy/apps/files/files/cozy-files'
    home:          '/usr/local/cozy/apps/home/home/cozy-home'
    notes:         '/usr/local/cozy/apps/notes/notes/cozy-notes'
    photos:        '/usr/local/cozy/apps/photos/photos/cozy-photos'
    proxy:         '/usr/local/cozy/apps/proxy/proxy/cozy-proxy'
    todos:         '/usr/local/cozy/apps/todos/todos/cozy-todos'

if appList[process.argv[2]]?
    appPath = appList[process.argv[2]]
else
    appPath = process.argv[2]

if process.argv[3] is '--rebuild'
    console.log "Rebuilding modules in #{appPath}"
    result = sh.exec "cd #{appPath} && rm -rf node_modules && npm install --production"
    if result.code isnt 0
        console.log result.stdout

console.log "Moving shared modules from #{appPath}"
sharedPath = '/usr/local/lib/node_shared_modules'
mkdirp.sync sharedPath

checkSharedDependencies = (callback) ->
    console.log 'Consolidating shared modules'
    exec "find #{sharedPath} -maxdepth 2 -type d | grep -E '^#{sharedPath}/(.*)/(.*)' | xargs -I folder npm --prefix folder update folder --production", (error, stdout, stderr) ->
        console.log stdout
        console.log error if error
        callback()

# NPM list based version
exec "cd #{appPath} && npm list --json", (error, stdout, stderr) ->
    mainModule = JSON.parse stdout
    if mainModule.problems
        console.log mainModule.problems
        console.log "There is a problem with your app's modules, please reinstall modules manually and try again"

    else
        #checkSharedDependencies () ->
            listModules = (dep, path, moduleList) ->
                if fs.existsSync "#{sharedPath}/module-list.json"
                    moduleList ?= require "#{sharedPath}/module-list.json"
                else
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

                    Array::unique = ->
                        output = {}
                        output[@[key]] = @[key] for key in [0...@length]
                        value for key, value of output

                    moduleList[moduleName][module.version].paths = moduleList[moduleName][module.version].paths.unique()
                    moduleList[moduleName][module.version].copies = moduleList[moduleName][module.version].paths.length
                    moduleList[moduleName][module.version].shared = moduleList[moduleName][module.version].paths.length > 1

                fs.writeFileSync "#{sharedPath}/module-list.json", JSON.stringify(moduleList, null, 4)
                return moduleList


            for module, versions of listModules mainModule.dependencies
                for version, info of versions
                    if info.shared

                        # Sort path (deepest locations first)
                        info.paths.sort (pathA, pathB) ->
                            if pathB.split('/').length > pathA.split('/').length
                                return -1
                            else
                                return 1

                        #TODO: Make this asynchronous ?
                        console.log module, version
                        sharedModulePath = "#{sharedPath}/#{module}"
                        mkdirp.sync sharedModulePath
                        if not fs.existsSync "#{sharedModulePath}/#{version}"
                            for i in [0...info.paths.length]
                                if fs.existsSync info.paths[i]
                                    fs.copySync info.paths[i], "#{sharedModulePath}/#{version}"
                                    break
                            if not fs.existsSync "#{sharedModulePath}/#{version}"
                                console.log 'No existing module found... Did you run npm install ?'
                            else
                                result = sh.exec "npm --prefix #{sharedModulePath}/#{version} install #{sharedModulePath}/#{version} --production"
                                if result.code isnt 0
                                    console.log result.stdout

                        for modulePath in info.paths
                            if fs.existsSync(modulePath) and fs.statSync(modulePath).isDirectory()
                                    rimraf.sync modulePath
                                    fs.symlinkSync "#{sharedModulePath}/#{version}", modulePath

            #checkSharedDependencies () ->
            #    console.log 'Done'
