![网站预览](https://juejin.58fe.com)
 
 网站地址：https://juejin.58fe.com

### 后端 Express 项目

##### 安装 Express

```
npm install -g typescript
npm install -g tslint
npm install --save express // 安装普通 express 模块，并在 dependencies 下生成包记录
npm install --save-dev @types/express // 安装带有声明文件的 express 模块，并在 devDependencies 下生成包记录，仅开发模式下安装。
```

### 目录结构

```js
 ├──backend
       ├──dist
       ├──src
          ├──app
          ├──controllers
       └──tsconfig.json
```

**app.ts**

```ts
import express from 'express'
import { NextFunction, Request, Response } from 'express' // express申明文件定义的类型

import * as listController from './controllers/list'
const app: express.Application = express()

app.get('/api/getList/:userId', listController.getLikeList)

app.use(function (err: Error, req: Request, res: Response, next: NextFunction) {
  return res.sendStatus(500)
})

app.listen(8001, function () {
  console.log(`the server is start at port 8001`)
})

export default app
```

开发 node+typescript 项目时，可以使用 ts-node 来调试代码，使用 tsc 编译代码

```json
"scripts": {
    "dev": "nodemon --watch 'src/' -e ts --exec 'ts-node' ./src/app.ts",
    "build": "tsc"
  }
```

##### 用 superagent 爬取数据

[superagent](https://cnodejs.org/topic/5378720ed6e2d16149fa16bd) 是 Node.js 里面一个蛮方便的客户端请求代理模块，用来打请求非常方便。

```ts
const request = require('superagent')
export const getLikeList = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  let result: any = []
  let { userId } = req.params
  let url = `https://user-like-wrapper-ms.juejin.im/v1/user/${userId}/like/entry`
  request
    .get(`${url}?page=0&pageSize=${pageSize}`)
    .set('X-Juejin-Src', 'web')
    .end((err, res) => {
      if (err) {
        return console.log(err)
      }

      let entryList = res.body.d.entryList
      const total = res.body.d.total
      let pages = Math.ceil(total / pageSize)
      entryList = handleResult(entryList)

      let promiseList: any[] = []
      for (let i = 1; i <= pages; i++) {
        promiseList.push(
          new Promise((resolve, reject) => {
            request
              .get(`${url}?page=${i}&pageSize=${pageSize}`)
              .set('X-Juejin-Src', 'web')
              .end((err, res) => {
                if (err) {
                  return console.log(err)
                }
                let entryList2 = JSON.parse(res.text).d.entryList
                entryList2 = handleResult(entryList2)
                resolve(entryList2)
              })
          })
        )
      }

      Promise.all(promiseList).then((rspList: any) => {
        result = [...entryList, ...flatten(rspList)]
      })
    })
}
```

##### pm2 进程管理工具

代码开发完毕要线上运行，并且保证服务稳定性，将使用 PM2 工具。本章讲解 PM2 的配置使用和进程守护，以及 PM2 多进程模型。
pm2 常见指令

```
npm install pm2 -g             全局安装 pm2
pm2 list                       列举所有正在运行的应用
pm2 start app.js               运行应用
pm2 stop app_name              停止应用(通过应用名称)
pm2 stop id                    停止应用(通过应用id)
pm2 stop all                   停止所有应用
pm2 restart app_name           重启应用(通过应用名称)
pm2 restart id                 重启应用(通过应用id)
pm2 restart all                重启所有应用
pm2 delete app_name            删除应用(通过应用名称)
pm2 delete id                  删除应用(通过应用id)
pm2 delete all                 删除所有应用
```

### 前端项目

##### 使用 create-react-app 一步步地创建一个 TypeScript 项目，并引入 antd。

```
npx create-react-app frontend --template typescript
cd frontend
```

##### 使用 customize-cra 修改 React 脚手架配置实践

安装 react-app-rewired ,[customize-cra](https://github.com/arackaf/customize-cra)，它提供一些修改 React 脚手架默认配置函数

```
npm i react-app-rewired customize-cra --save-dev
```

安装后，修改 package.json 文件的 scripts

```json
"scripts": {
    "start": "react-app-rewired start",
    "build": "react-app-rewired build",
    "test": "react-app-rewired test",
}
```

项目根目录创建一个 `config-overrides.js` 用于修改 Webpack 配置。

`antd-dayjs-webpack-plugin`是 Ant Design 官方推荐的插件，用于替换`moment.js`，你可以使用 antd-dayjs-webpack-plugin 插件用 Day.js 替换 momentjs 来大幅减小打包大小。
| Name | Size | Size gzip |
|-----------|----------|-----------|
| Day.js | 11.11 kb | 4.19 kb |
| Moment.js | 231 kb | 65.55 kb |

Ant Design 提供了一个按需加载的 babel 插件 `babel-plugin-import`

安装 `npm i babel-plugin-import --save-dev,`并修改`config-overrides.js` 配置文件

```js
const { override, fixBabelImports，addWebpackPlugin } = require('customize-cra');
const AntdDayjsWebpackPlugin = require('antd-dayjs-webpack-plugin');
//override函数用来覆盖React脚手架Webpack配置；fixBabelImports修改babel配置
module.exports = override(
  fixBabelImports('import', {
    libraryName: 'antd',
    libraryDirectory: 'es',
    style: 'css',
 }),
   addWebpackPlugin(new AntdDayjsWebpackPlugin())
);
```

##### 前端项目 cdn 配置

antd 项目更目录下加.env 文件,cdn 用的是[七牛云](https://portal.qiniu.com/signup?code=1hjz770w7klle)

```
PUBLIC_URL = 'http://cdn.58fe.com/juejin-helper/'
```

### 前端 nginx 配置

```nginx
server {
  # 80端口是http正常访问的接口
  listen 80;
  server_name juejin.58fe.com;
  # 在这里，我做了https全加密处理，在访问http的时候自动跳转到https
  rewrite ^(.*) https://$host$1 permanent;
}
server {
    listen 443 ssl;
    server_name juejin.58fe.com;
    server_name_in_redirect off;

    #可以设置独立的ssl认证
    ssl_certificate /58fe/ssl/juejin/juejin.58fe.com_chain.crt;
    ssl_certificate_key /58fe/ssl/juejin/juejin.58fe.com_key.key;
    ssl_session_timeout 5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   Host      $http_host;
        root  /58fe/juejin-helper/frontend/build;
        try_files $uri $uri/ /index.html;
    }
    # localhost/a 的请求会被均匀分发到myserver
    location ~ /api/ {
         # 负载均衡名(用于进行负载均衡的配置)
        proxy_pass https://juejin-api.58fe.com;
         # 设置用户真实ip否则获取到的都是nginx服务器的ip
         proxy_set_header X-real-ip $remote_addr;
         proxy_set_header Host $http_host;
    }
}
server {
    listen 443 ssl;
    server_name juejin-api.58fe.com;
    server_name_in_redirect off;

    #可以设置独立的ssl认证
    ssl_certificate /58fe/ssl/juejin/api/juejin-api.58fe.com_chain.crt;
    ssl_certificate_key /58fe/ssl/juejin/api/juejin-api.58fe.com_key.key;
    ssl_session_timeout 5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;

    location / {
      tcp_nodelay on;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_pass http://127.0.0.1:8001;
    }
}
```

### docker-compose 部署

##### 安装 Docker 并启动 Docker

```
// 更新软件库
yum update -y

// 安装 docker
yum install docker -y

// 启动 docker 服务
service docker start

// 重启docker 服务
service docker restart

// 停止 docker 服务
service docker stop
```

##### Docker 部署

// 下载并安装 docker-compose (\可以根据实际情况修改最新版本)

```
curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose

// 授予执行权限
chmod +x /usr/local/bin/docker-compose

// 安装完查看版本
docker-compose -version
```

##### 认识一下 Dockerfile 的指令

From: 基础镜像<br/>
MAINTAINER：维护者信息<br/>
RUN：执行命令<br/>
ADD： copy 文件<br/>
WORKDIR：类似 cd 命令，当前工作目录<br/>
VOLUME：目录挂载<br/>
EXPOSE：端口<br/>
RUN： 启动一个容器、执行命令<br/>

##### Docker Compose

Docker Compose 是一个工具，可以通过一个 yml 文件定义多容器的 Docker 应用。
编排容器执行顺序，通过一条命令就可以根据 yml 文件的定义去创建或者管理多个容器，相对于一个一个 docker run 方式运行项目，管理和创建容器更方便。

利用来 docker-compose 部署前端 react 项目的 build 目录到 Nginx 中，后端则是一个 nodejs 服务, Docker Compose 创建容器只需要编写好 yml 文件，然后执行一行命令就可以。

**编写 docker-compose.yml 文件**

```yml
version: '3'
services:
  juejin-web: # 前端web容器(运行nginx中的React项目)
    container_name: juejin-web-container
    image: nginx
    restart: always
    build: ./
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./frontend/build:/58fe/juejin-helper/build #挂载项目
    ports:
      - '80:80' # 映射端口
    depends_on: # 依赖于api容器，被依赖容器启动后此web容器才可启动
      - juejin-api
  juejin-api: # 后端express容器
    container_name: juejin-api-container
    restart: always # 重启策略: 容器退出时总是重启容器
    build: ./backend # 指定设定上下文根目录，然后以该目录为准指定Dockerfile
    ports: # 映射端口
      - '8001:8001'
    command: node  dist/app # 容器创建后执行命令
```

部署后端项目-> npm i && npm run build && node dist/app<br/>
部署前端项目-> npm i && npm run buld -> COPY 到 nginx 中运行<br/>
通过 docker-compose 编排一下执行顺序，① 后端 api 容器 ② 前端 web 容器<br/>
docker-compose build -> 构建镜像<br/>
docker-compose up -d -> 启动应用服务<br/>
docker-compose down ->停止服务<br/>
docker ps -a ->显示所有的容器<br/>
docker rm `docker ps -a | grep Exited | awk '{print $1}'` 删除已停止的 docker 容器

![docker部署完成](https://cdn.58fe.com/juejin-helper/docker-images.jpg)

5. 在 dockerHub 上授权 github 项目，这样当 github 项目有更新时，会自动执行 Dockerfile 进行构建，并将构建结果保存到 dockerHub 仓库中。

### 参考文章

1. [Github + Jenkins + Docker 实现自动化部署](https://github.com/mcuking/blog/issues/61)
2. [docker-compose 部署 Vue+SpringBoot 前后端分离项目](https://segmentfault.com/a/1190000021008496)
