#pragma once

#include "macro_utils.h"

#define VM_MAX_COMMAND_LENGTH_MACRO 10
#define VM_COMMAND_NAME_SCANF_FORMAT "%" EXPAND(VM_MAX_COMMAND_LENGTH_MACRO) "s"

const size_t VM_COMMAND_NAME_MAX_LENGTH = VM_MAX_COMMAND_LENGTH_MACRO;