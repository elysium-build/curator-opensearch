ARG BASE_IMAGE=""
ARG BASE_IMAGE_TAG=""

FROM python:3.11.3-alpine3.18 as builder

COPY fpx.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

# Add the community repo for access to patchelf binary package
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/v3.16/community/' >> /etc/apk/repositories
RUN apk --no-cache upgrade && apk --no-cache add build-base tar musl-utils openssl-dev patchelf
# patchelf-wrapper is necessary now for cx_Freeze, but not for Curator itself.
RUN pip3 install -trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org cx_Freeze patchelf-wrapper

COPY . .
RUN ln -s /lib/libc.musl-x86_64.so.1 ldd
RUN ln -s /lib /lib64
RUN pip3 install -trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org -r requirements.txt
RUN python3 setup.py build_exe


FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG}
RUN apk --no-cache upgrade && apk --no-cache add openssl-dev expat
COPY --from=builder build/exe.linux-x86_64-3.11 /curator/
RUN mkdir /.curator

USER nobody:nobody
ENV LD_LIBRARY_PATH /curator/lib:$LD_LIBRARY_PATH
ENTRYPOINT ["/curator/curator"]


