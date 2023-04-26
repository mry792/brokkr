#! /usr/bin/env python3

from pathlib import Path
from textwrap import dedent

from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout
from conan.tools.files import save, update_conandata
from conan.tools.scm import Git


class BrokkrRecipe (ConanFile):
    name = 'brokkr'
    # version = (computed from local repo)

    author = 'M. Emery Goss <m.goss792@gmail.com>'
    url = 'https://github.com/mry792/brokkr.git'
    description = (
        'An opinionated library of CMake functions to simplify building and '
        'packaging C++ projects.'
    )

    settings = 'build_type',
    generators = 'CMakeToolchain'

    @property
    def git (self):
        return Git(self, self.recipe_folder)

    def package_id (self):
        self.info.clear()

    def set_version (self):
        tag = self.git.run('describe --tags')
        self.version = tag[1:]

    def export (self):
        scm_url, scm_commit = self.git.get_url_and_commit()
        update_conandata(self, {
            'source': {
                'commit': scm_commit,
                'url': scm_url,
            }
        })

    def source (self):
        git = Git(self)
        source = self.conan_data['source']
        git.clone(source['url'], target = '.')
        git.checkout(source['commit'])

    def layout (self):
        cmake_layout(self)

    def build (self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    @property
    def _toolchain_file (self):
        return Path('lib', 'cmake', self.name, 'dependent-toolchain.cmake')

    def package (self):
        cmake = CMake(self)
        cmake.install()

        # Brokkr provides it's own CMake config file. To make sure dependent
        # packages can find it, we generate a custom toolchain to be used by
        # dependent recipes that defines `brokkr_ROOT`.
        # https://cmake.org/cmake/help/latest/command/find_package.html#search-procedure
        save(
            self,
            self.package_folder / self._toolchain_file,
            dedent(
                '''
                include_guard()
                message(STATUS "[brokkr] Using brokkr dependent-toolchain: ${CMAKE_CURRENT_LIST_FILE}")
                set(brokkr_ROOT ${CMAKE_CURRENT_LIST_DIR}/../../..)
                cmake_path(NORMAL_PATH brokkr_ROOT)
                '''
            ),
        )

    def package_info (self):
        self.cpp_info.set_property('cmake_find_mode', 'none')
        self.conf_info.append(
            'tools.cmake.cmaketoolchain:user_toolchain',
            str(self.package_folder / self._toolchain_file),
        )
