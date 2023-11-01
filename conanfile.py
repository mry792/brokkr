#! /usr/bin/env python3

from pathlib import Path
from textwrap import dedent

from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, cmake_layout
from conan.tools.files import copy, save, update_conandata
from conan.tools.scm import Git


class BrokkrRecipe (ConanFile):
    name = 'brokkr'
    # version = (computed from local repo or specified at package creation)

    author = 'M. Emery Goss <m.goss792@gmail.com>'
    url = 'https://github.com/mry792/brokkr.git'
    description = (
        'An opinionated library of CMake functions to simplify building and '
        'packaging C++ projects.'
    )

    settings = 'build_type',

    def _has_git_repo (self, path):
        try:
            git = Git(self, path)
            path = Path(path).resolve()
            repo_root = Path(git.get_repo_root()).resolve();
            return path == repo_root
        except Exception:
            return False

    def set_version (self):
        if not self.version:
            git = Git(self, self.recipe_folder)
            tag = git.run('describe --tags')
            self.version = tag[1:]

    @property
    def _toolchain_file (self):
        return Path('lib', 'cmake', self.name, 'dependent-toolchain.cmake')

    ###
    # RECIPE STEPS
    ###

    def export (self):
        git = Git(self, self.recipe_folder)
        if self._has_git_repo(self.recipe_folder):
            scm_url, scm_commit = git.get_url_and_commit()
            update_conandata(self, {
                'source': {
                    'commit': scm_commit,
                    'url': scm_url,
                }
            })
            return

        update_conandata(self, {
            'source': { 'url': '(local)' }
        })

    def export_sources (self):
        if not self._has_git_repo(self.recipe_folder):
            copy(self, '*.cmake')
            copy(self, '*.cmake.in')
            copy(self, 'CMakeLists.txt')
            copy(self, 'LICENSE')
            copy(self, 'README.md')

    def layout (self):
        cmake_layout(self)

    def package_id (self):
        self.info.clear()

    def source (self):
        source = self.conan_data['source']
        if source['url'] != '(local)':
            git = Git(self, self.source_folder)
            git.clone(source['url'], target = '.')
            git.checkout(source['commit'])

    def generate (self):
        tc = CMakeToolchain(self)
        if self.conan_data['source']['url'] == '(local)':
            tc.cache_variables['BROKKR_THIS_PROJECT_VERSION:STRING'] = self.version
        tc.generate()

    def build (self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

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
