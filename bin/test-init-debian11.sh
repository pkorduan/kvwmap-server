#!/bin/bash

docker run -it \
-v $(pwd)/init-debian11.sh:/init.sh \
--user=root \
--name=init-debian \
debian \
/init.sh

docker commit init-debian gkaemmert/init-debian
docker rm -f init-debian
docker run --rm -it gkaemmert/init-debian bash
