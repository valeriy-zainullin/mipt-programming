#pragma once

#include "macro_utils.h"
#include "status.h"

#include <stdbool.h>
#include <stddef.h>

#define VM_LABEL_NAME_MAX_LENGTH_MACRO 256
#define VM_LABEL_NAME_SCANF_FORMAT " %" EXPAND(VM_LABEL_NAME_MAX_LENGTH_MACRO) "[a-zA-Z0-9_]"
#define VM_LABEL_DECL_SCANF_FORMAT VM_LABEL_NAME_SCANF_FORMAT ":"

static const size_t VM_ASSEMBLY_MAX_NUMBER_OF_LABELS = 1024;
static const size_t VM_ASSEMBLY_MAX_LABEL_LENGTH = VM_LABEL_NAME_MAX_LENGTH_MACRO;

struct VmAssemblyLabel {
	bool defined;
	char name[VM_ASSEMBLY_MAX_LABEL_LENGTH + 1];
	size_t addr = 0;
};

struct VmAssemblyLabels {
	VmAssemblyLabel labels[VM_ASSEMBLY_MAX_NUMBER_OF_LABELS];
	size_t nlabels;
};

bool vm_text_read_label_decl(VmAssemblyStatus* status, FILE* input_stream, char* label);