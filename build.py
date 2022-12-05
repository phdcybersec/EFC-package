from Cython.Build import cythonize

exclude_list = [
#    "sample_package/excluded_module/**",
]
compiler_directives = {"language_level": 3, "embedsignature": True}

def build(setup_kwargs):
    setup_kwargs.update(
        {
            "name": "efc",
            "package": ["efc"],
            # https://cython.readthedocs.io/en/latest/src/userguide/source_files_and_compilation.html#cythonize-arguments
            "ext_modules": cythonize("efc/_base_fast.pyx"),
        }
    )