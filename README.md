# minectl-fn

Serverless Fn mainly for [minectl 🗺](https://github.com/dirien/minectl) which runs at the moment on Google cloud run.

## Functions 📒

### Java Server Version

#### Latest Version

Calling this Function, gives you the current version of Minecraft back.
```bash
curl https://java-version.minectl.ediri.online/latest
1.17.1
```

#### Download Url for a Version

Calling this Function with a specific version, gives you the download URL for the corresponding server version. 
```bash
curl https://java-version.minectl.ediri.online/binary/1.17
https://launcher.mojang.com/v1/objects/0a269b5f2c5b93b1712d0f5dc43b6182b9ab254e/server.jar

curl https://java-version.minectl.ediri.online/binary/1.12
https://launcher.mojang.com/v1/objects/8494e844e911ea0d63878f64da9dcc21f53a3463/server.jar%
```

## Legal Disclaimer 👮
This project is not affiliated with Mojang Studios, XBox Game Studios, Double Eleven or the Minecraft brand.

"Minecraft" is a trademark of Mojang Synergies AB.

Other trademarks referenced herein are property of their respective owners.