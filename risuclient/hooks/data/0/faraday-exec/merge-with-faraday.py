#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Hook for moving faraday-exec results into regular faraday
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2018-2021, 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
from __future__ import print_function

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
    for pluginid in data:
        if data[pluginid]["backend"] == "faraday-exec":
            data[pluginid]["backend"] = "faraday"

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _(
        "This hook proceses faraday-exec results and converts to faraday for Magui plugin to work"
    )
    return commandtext
