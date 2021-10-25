#pragma once

#include <stddef.h>

struct Variable {
	const char* file;
	size_t line;
	const char* function;
	const char* name;
};
typedef struct Variable Variable;

#if defined(__GNUC__)
#define MAY_BE_UNUSED __attribute__((unused))
#endif

MAY_BE_UNUSED static Variable make_variable_location(const char* source_file, size_t line, const char* function, const char* variable) {
	Variable variable_location = {source_file, line, function, variable};
	return variable_location;
}

#define MAKE_VARIABLE_LOCATION(VARIABLE) make_variable_location(__FILE__, __LINE__, __func__, #VARIABLE)
