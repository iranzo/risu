#!/usr/bin/env python
# encoding: utf-8

# Copyright (C) 2019, 2022, 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>


import os
from unittest import TestCase

import pytest

import risuclient.shell as risu

testplugins = os.path.join(risu.risudir, "plugins", "test")
risudir = risu.risudir


class CitellusTest(TestCase):
    @pytest.mark.last
    def test_plugins_have_description(self):
        global extensions
        extensions, exttriggers = risu.initPymodules()
        # get all plugins
        plugins = []

        # code
        for plugin in risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core")]
        ):
            plugins.append(plugin)

        # ansible
        for plugin in risu.findplugins(
            executables=False,
            fileextension=".yml",
            extension="ansible",
            folders=[os.path.join(risu.risudir, "plugins", "ansible")],
        ):
            plugins.append(plugin)

        for plugin in plugins:
            if plugin["description"] == "":
                print(plugin)
            assert plugin["description"] != ""

    @pytest.mark.last
    def test_plugins_have_long_name(self):
        global extensions
        extensions, exttriggers = risu.initPymodules()
        # get all plugins
        plugins = []

        # code
        for plugin in risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core")]
        ):
            plugins.append(plugin)

        # ansible
        for plugin in risu.findplugins(
            executables=False,
            fileextension=".yml",
            extension="ansible",
            folders=[os.path.join(risu.risudir, "plugins", "ansible")],
        ):
            plugins.append(plugin)

        for plugin in plugins:
            if plugin["long_name"] == "":
                print(plugin)
            assert plugin["long_name"] != ""
