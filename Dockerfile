# 小体积的 node 镜像
FROM mhart/alpine-node

RUN echo "-------------------- 前端react项目环境配置 --------------------"

RUN mkdir -p /58fe/juejin-helper/

COPY . /58fe/juejin-helper/
# 指定接下来的工作路径为/usr/src/juejin - 类似于cd命令
WORKDIR /58fe/juejin-helper/frontend

# 安装依赖
RUN npm i --production

# 打包 - 目的：丢到nginx下跑
RUN npm run build

# 前端项目运行命令
#CMD ["npm","run","start"]

# 拷贝前端vue项目打包后生成的文件到nginx目录下
# COPY  /forontend/build /58fe/juejin-helper

# 使用daemon off的方式将nginx运行在前台保证镜像不至于退出
CMD ["nginx", "-g", "daemon off;"]
# 注：CMD不同于RUN，CMD用于指定在容器启动时所要执行的命令，而RUN用于指定镜像构建时所要执行的命令。
#    RUN指令创建的中间镜像会被缓存，并会在下次构建中使用。如果不想使用这些缓存镜像，可以在构建时指定--no-cache参数，如：docker build --no-cache
