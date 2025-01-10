from typing import Literal

import pydantic

from rendercv.themes.common_options import LaTeXDimension, ThemeOptions


class V0ThemeOptions(ThemeOptions):
    """This class is the data model of the theme options for the `v0` theme."""

    theme: Literal["v0"]
    font: str = "Helvetica"