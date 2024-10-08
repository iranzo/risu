#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Hook for moving rhv-log-collector-analyzer results to individual tests results
# Copyright (C) 2018-2021, 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
from __future__ import print_function

import json
import os

try:
    import risuclient.shell as risu
except:
    import shell as risu

# Load i18n settings from risu
_ = risu._

extension = "__file__"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    return []


def run(data, quiet=False, options=None):  # do not edit this line
    """
    Executes plugin
    :param quiet: be more silent on returned information
    :param data: data to process
    :return: returncode, out, err
    """

    # Act on all faraday-exec plugins
    idstodel = []
    datatoadd = []

    rhvlcid = risu.calcid(
        string="/plugins/rhv-log-collector-analyzer/virtualization/base.txt"
    )
    # Loop over plugin id's in data
    for pluginid in data:
        if (
            data[pluginid]["id"] == rhvlcid
            and data[pluginid]["result"]["rc"] == risu.RC_OKAY
        ):
            # Make a copy of dict for working on it
            try:
                plugin = json.loads(data[pluginid]["result"]["err"])[
                    "rhv-log-collector-analyzer"
                ]
            except:
                plugin = None

            # Fake data until we've the way to run it
            # plugin = json.load(open('/home/iranzo/DEVEL/risu/risu/logcollector2.json', 'r'))['rhv-log-collector-live']

            # Add plugin ID to be removed for resulting data
            idstodel.append(str(pluginid))

            # Iterate over plugindata items
            for item in plugin:
                # Item ID in log-collector is not unique
                newid = item["id"]

                if "WARNING" in item["type"]:
                    returncode = risu.RC_FAILED
                else:
                    returncode = risu.RC_OKAY

                # Write plugin entry for the individual result
                newitem = {
                    newid: {
                        "name": "rhv-log-collector-analyzer: %s" % item["name"],
                        "description": item["description"],
                        "long_name": item["name"],
                        "id": newid,
                        "category": "",
                        "priority": 400,
                        "bugzilla": item["bugzilla"],
                        "time": item["time"],
                        "subcategory": "",
                        "hash": item["hash"],
                        "result": {
                            "out": "",
                            "err": "%s" % item["result"],
                            "rc": returncode,
                        },
                        "plugin": item["path"],
                        "backend": "rhv-log-collector-analyzer",
                        "kb": item["kb"],
                    }
                }

                datatoadd.append(newitem)

    # Process id's to remove
    for id in idstodel:
        del data[id]

    # Process data to add
    for item in datatoadd:
        data.update(item)

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _(
        "This hook proceses rhv-log-collector-analyzer results and converts to individual plugins"
    )
    return commandtext
