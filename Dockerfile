# Galacticus Docker image
# Uses Docker multi-stage build to build Galacticus.

FROM galacticusorg/buildenv:latest as build

# Set build options.
## * The flags are also set in galacticus/buildenv:latest so we don't really need to reset them here.
## * We force use of the BFD linker here. The GCC in galacticus/buildenv:latest uses the gold linker by default. But, the gold
##   linker seems to not correctly allow us to get values of some GSL constants (e.g. gsl_root_fsolver_brent) in Fortran.
ENV GALACTICUS_FCFLAGS "-fintrinsic-modules-path $INSTALL_PATH/finclude -fintrinsic-modules-path $INSTALL_PATH/include -fintrinsic-modules-path $INSTALL_PATH/include/gfortran -fintrinsic-modules-path $INSTALL_PATH/lib/gfortran/modules -L$INSTALL_PATH/lib -L$INSTALL_PATH/lib64 -fuse-ld=bfd"
ENV GALACTICUS_CFLAGS "-fuse-ld=bfd"
ENV GALACTICUS_CPPFLAGS "-fuse-ld=bfd"
ENV GALACTICUS_EXEC_PATH /opt/galacticus
ENV GALACTICUS_DATA_PATH /opt/datasets

RUN     pwd && ls

# Clone datasets.
RUN     cd /opt &&\
	git clone --depth 1 https://github.com/galacticusorg/galacticus.git galacticus
	git clone --depth 1 https://github.com/galacticusorg/datasets.git datasets

# Build Galacticus.
RUN     cd /opt/galacticus &&\
	make -j4 Galacticus.exe

# Build external tools.
RUN     cd /opt/galacticus &&\
	./Galacticus.exe parameters/buildTools.xml &&\
	rm /opt/datasets/dynamic/c17.01.tar.gz /opt/datasets/dynamic/CAMB.tar.gz
	
