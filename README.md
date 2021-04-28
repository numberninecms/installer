![NumberNine Logo](./NumberNine512_slogan.png)

<br>

[![Github Workflow](https://github.com/numberninecms/installer/workflows/Installer builder/badge.svg)](https://github.com/numberninecms/installer/actions)

# Documentation
Visit https://numberninecms.github.io/ for user and developer documentation.

This is a Docker installer builder for NumberNine CMS. It creates an up-to-date NumberNine project with a full docker environment.

To create a new NumberNine project, simply run this one-liner:

```bash
docker run --rm -t -e HOST_PWD=$PWD -v $PWD:/srv/app \
    -v /var/run/docker.sock:/var/run/docker.sock \
    numberninecms/installer myproject
```

Replace `myproject` by the name of your project. Done!

# Contributions
Feel free to submit issues and pull requests.

# License
[MIT](LICENSE)

Copyright (c) 2020-2021, William Arin
