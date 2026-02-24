#
# <meta:header>
#   <meta:licence>
#     Copyright (c) 2026, Manchester (http://www.manchester.ac.uk/)
#
#     This information is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This information is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this software. If not, see <http://www.gnu.org/licenses/>.
#   </meta:licence>
# </meta:header>
#
# AIMetrics: [
#     {
#     "name": "ChatGPT",
#     "model": "ChatGPT 5.2",
#     "contribution": {
#       "value": 100,
#       "units": "%"
#       }
#     }
#   ]
#

FROM alpine:3.23

RUN apk add \
    --no-cache \
    coreutils \
    jc

RUN adduser \
    -D \
    -H \
    -u 10001 \
    app

WORKDIR /app

COPY bin/hashwrap.sh /usr/local/bin/hashwrap
RUN chmod +x /usr/local/bin/hashwrap

USER app

ENTRYPOINT ["/usr/local/bin/hashwrap"]
# Default args to the ENTRYPOINT:
#   HASH=md5sum, FORMAT=json
CMD ["md5sum", "json"]

