#!/usr/bin/env python3
import logging
import os
import sys


LEVEL_COLORS = {
  logging.DEBUG: "\033[90m",
  logging.INFO: "\033[34m",
  logging.WARNING: "\033[33m",
  logging.ERROR: "\033[31m",
  logging.CRITICAL: "\033[31;1m",
}
RESET = "\033[0m"


class _ColorFormatter(logging.Formatter):
  def __init__(self, use_color: bool):
    super().__init__(fmt="[%(asctime)s %(levelname)s] %(message)s", datefmt="%H:%M:%S")
    self.use_color = use_color

  def format(self, record):
    base = super().format(record)
    if not self.use_color:
      return base
    color = LEVEL_COLORS.get(record.levelno, "")
    if not color:
      return base
    return f"{color}{base}{RESET}"


def get_logger(name: str) -> logging.Logger:
  logger = logging.getLogger(name)
  if logger.handlers:
    return logger

  no_color = os.environ.get("NO_COLOR", "0") == "1"
  use_color = sys.stdout.isatty() and not no_color
  handler = logging.StreamHandler(stream=sys.stdout)
  handler.setFormatter(_ColorFormatter(use_color=use_color))
  logger.addHandler(handler)

  debug = os.environ.get("DEBUG", "0") == "1"
  logger.setLevel(logging.DEBUG if debug else logging.INFO)
  logger.propagate = False
  return logger
