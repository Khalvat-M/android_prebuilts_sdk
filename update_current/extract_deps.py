#!/usr/bin/python3

# This script is used to generate flattened lists of transitive dependencies
# for consumption by build/make/core/support_libraries.mk based on the output
# of the pom2mk tool. Typically, this script should only be called by
# update_current.py; however, it may also be run manually against the
# Android.mk generated by that script.
import sys, argparse, os
from string import Template
from functools import reduce


def flatten(list):
    return reduce((lambda x, y: "%s %s" % (x, y)), list)


# Read remaining tokens, treating a trailing \ as a line continuation.
def parse_tokens(remaining, source):
    tokens = []
    i = 0
    while i < len(remaining):
        token = remaining[i]
        if token == "\\":
            remaining = source.readline().split()
            i = 0
        else:
            tokens += [token]
            i += 1
    return tokens


# Parse makefiles to generate dependencies
def parse_deps(sources):
    deps = {}

    for source in sources.split(','):
        parse_deps_from_makefile(deps, source)

    return deps


# Parse makefile into dependency map
def parse_deps_from_makefile(deps, source):
    s = open(source)

    module = ""
    suffix = ""
    a_deps = []
    j_deps = []

    line = s.readline()
    while line:
        tokens = line.split()
        if not tokens:
            line = s.readline()
            continue
        if tokens[0] == "include":
            if tokens[1] == "$(CLEAR_VARS)":
                a_deps = []
                j_deps = []
            elif tokens[1] == "$(BUILD_STATIC_JAVA_LIBRARY)"\
                    or (tokens[1] == "$(BUILD_PREBUILT)" and "-nodeps" not in module):
                deps[module] = [suffix, a_deps, j_deps, False]
        elif tokens[0] == "LOCAL_STATIC_ANDROID_LIBRARIES":
            a_deps += parse_tokens(tokens[2:], s)
        elif tokens[0] == "LOCAL_STATIC_JAVA_LIBRARIES":
            j_deps += parse_tokens(tokens[2:], s)
        elif tokens[0] == "LOCAL_MODULE":
            module = tokens[2]
        elif tokens[0] == "LOCAL_MODULE_SUFFIX":
            suffix = tokens[2]
        line = s.readline()

    s.close()


# Recursively expand all dependencies
def expand_deps(deps):
    for module in deps:
        expand_deps_helper(module, deps)


def expand_deps_helper(module, deps):
    if module not in deps:
        return [],[]
    if deps[module][3]:
        return deps[module][1], deps[module][2]

    adep_transitive = []
    jdep_transitive = []
    for dep in deps[module][1] + deps[module][2]:
        (adeps, jdeps) = expand_deps_helper(dep, deps)
        adep_transitive += adeps
        jdep_transitive += jdeps

        # Strip "shallow" modules used for static inclusion. We can remove this
        # after turning off --static-deps in update_current.py.
        if dep + "-nodeps" in adeps and dep in deps[module][1]:
            deps[module][1].remove(dep)
        if dep + "-nodeps" in jdeps and dep in deps[module][2]:
            deps[module][2].remove(dep)

    # If the module isn't shallow, make sure it relies on itself.
    if deps[module][0] == ".aar":
        if module + "-nodeps" not in deps[module][1]:
            deps[module][1].append(module)
    if deps[module][0] == ".jar":
        if module + "-nodeps" not in deps[module][2]:
            deps[module][2].append(module)

    deps[module][1] = list(set(deps[module][1] + adep_transitive))
    deps[module][2] = list(set(deps[module][2] + jdep_transitive))
    deps[module][3] = True

    deps[module][1].sort()
    deps[module][2].sort()

    return deps[module][1], deps[module][2]


# Write out template containing dependencies
def write_deps(deps):
    # Load templates.
    dep_tmpl = Template(' \\\n'
                        '        $dep')
    knownlist = ""
    ruleslist = ""
    for module, entry in sorted(deps.items()):
        suffix = entry[0]
        adeps = entry[1]
        jdeps = entry[2]

        knownlist += ' \\\n    ' + module

        adepslist = ""
        for dep in adeps:
            adepslist += dep_tmpl.substitute(dep=dep)

        jdepslist = ""
        for dep in jdeps:
            jdepslist += dep_tmpl.substitute(dep=dep)

        ruleslist += 'ifneq (,$(filter ' + module + ',$(requested_support_libs)))\n'
        if adepslist:
            ruleslist += '    support_android_deps +=' + adepslist + '\n'
        if jdepslist:
            ruleslist += '    support_java_deps +=' + jdepslist + '\n'
        ruleslist += 'endif\n\n'

    output_tmpl = Template(open(script_relative('extract_deps.tmpl')).read())
    return output_tmpl.substitute(command=flatten(sys.argv), known=knownlist, rules=ruleslist)


def write_file(output, destination):
    d = open(destination, "w")
    d.write(output)
    d.close()


def script_relative(rel_path):
    return os.path.join(os.path.dirname(os.path.realpath(sys.argv[0])), rel_path)


parser = argparse.ArgumentParser(
    description='Generate include for adding explicit dependencies')
parser.add_argument(
    'source',
    help='Path to Makefile defining top-level targets')
parser.add_argument(
    '-o', '--output',
    help='Path to output Makefile for use as include')
args = parser.parse_args()

if not args.source:
    parser.error("You must specify the path to Makefile defining top-level targets")
    sys.exit(1)

deps_map = parse_deps(args.source)
expand_deps(deps_map)
output = write_deps(deps_map)

if args.output:
    write_file(output, args.output)
else:
    print(output)
