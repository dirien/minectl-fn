# minectl-fn

Serverless Fn mainly for [minectl 🗺](https://github.com/dirien/minectl) which runs at the moment on Google cloud run.

## Functions 📒

### Java Server Version

#### Latest Version

Calling this Function, gives you the current Java download URL back.

```bash
curl https://java-version.minectl.ediri.online/latest
https://launcher.mojang.com/v1/objects/a16d67e5807f57fc4e550299cf20226194497dc2/server.jar
```

#### Download Url for a Version

Calling this Function with a specific version, gives you the download URL for the corresponding server version.

```bash
curl https://java-version.minectl.ediri.online/binary/1.17
https://launcher.mojang.com/v1/objects/0a269b5f2c5b93b1712d0f5dc43b6182b9ab254e/server.jar

curl https://java-version.minectl.ediri.online/binary/1.12
https://launcher.mojang.com/v1/objects/8494e844e911ea0d63878f64da9dcc21f53a3463/server.jar
```

### Bedrock Server Version

As I host this functions on GCP, it looks like the the Mojang page is blocking the scraping
of `https://www.minecraft.net/en-us/download/server/bedrock`.

So I scrape `https://minecraft.fandom.com/wiki/Bedrock_Dedicated_Server` and hope that the good folks their are quick to
update their page.

#### Latest Version

Calling this Function, gives you the current Bedrock download URL back.

```bash
curl https://bedrock-version.minectl.ediri.online/latest
https://minecraft.azureedge.net/bin-linux/bedrock-server-1.17.10.04.zip
```

#### Download Url for a Version

Calling this Function with a specific version, gives you the download URL for the corresponding server version.

```bash
curl https://bedrock-version.minectl.ediri.online/binary/1.16.221.01
https://minecraft.azureedge.net/bin-linux/bedrock-server-1.16.221.01.zip

curl https://bedrock-version.minectl.ediri.online/binary/1.14.60.5
https://minecraft.azureedge.net/bin-linux/bedrock-server-1.14.60.5.zip
```

### Download Install Script

Calling this function will return the `install.sh`

```bash
curl https://get.minectl.dev
```
Best is to pipe the curl into a shell:

```bash
curl -sLS https://get.minectl.dev | sudo sh
```

```bash
curl -sLS https://get.minectl.dev | sh
```

### Libraries & Tools 🔥

- https://github.com/go-resty/resty
- https://github.com/gocolly/colly
- https://github.com/gorilla/mux
- https://github.com/hashicorp/go-version

## Legal Disclaimer 👮

This project is not affiliated with Mojang Studios, XBox Game Studios, Double Eleven or the Minecraft brand.

"Minecraft" is a trademark of Mojang Synergies AB.

Other trademarks referenced herein are property of their respective owners.