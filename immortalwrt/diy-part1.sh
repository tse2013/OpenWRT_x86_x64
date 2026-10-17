#!/bin/bash

# Merge_package
function merge_package(){
    repo=`echo $1 | rev | cut -d'/' -f 1 | rev`
    pkg=`echo $2 | rev | cut -d'/' -f 1 | rev`
    # find package/ -follow -name $pkg -not -path "package/openwrt-packages/*" | xargs -rt rm -rf
    git clone --depth=1 --single-branch $1
    [ -d package/openwrt-packages ] || mkdir -p package/openwrt-packages
    mv $2 package/openwrt-packages/
    rm -rf $repo
}

rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# Clone community packages to package/community
mkdir package/community
pushd package/community
git clone --depth=1 https://github.com/fw876/helloworld
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall2
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki
git clone --depth=1 https://github.com/DHDAXCW/dhdaxcw-app
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config
git clone --depth=1 https://github.com/DHDAXCW/istore
git clone --depth=1 https://github.com/Siriling/5G-Modem-Support && rm -rf 5G-Modem-Support/rooter
git clone --depth=1 https://github.com/gdy666/luci-app-lucky
# 25.12 的 luci 已移除 luci-app-socat
git clone --depth=1 https://github.com/chenmozhijin/luci-app-socat
popd

# 25.12 官方 luci-app-adguardhome 无中文翻译，改用 dhdaxcw-app 中带中文的版本
rm -rf feeds/luci/applications/luci-app-adguardhome package/feeds/luci/luci-app-adguardhome

# 25.12: 改用官方 feeds 的 quectel-cm（5G-Modem-Support 自带的 1.6.7 哈希与新版 git 打包方式不符）
rm -rf package/community/5G-Modem-Support/quectel_cm_5G
# 25.12: git 源码包打包方式变化导致 PKG_MIRROR_HASH 不匹配，源码 commit 不变，跳过校验
sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/' package/community/helloworld/shadowsocks-libev/Makefile
# 25.12 (kernel 6.12): 移远 pcie_mhi 驱动适配新内核接口
sed -i 's/\bno_llseek\b/noop_llseek/; s/static int mhi_match(struct device \*dev, struct device_driver \*drv)/static int mhi_match(struct device *dev, const struct device_driver *drv)/' \
    package/community/5G-Modem-Support/quectel_MHI/src/core/mhi_init.c
# 25.12: upx 主机工具安装在 staging_dir/hostpkg 而非 staging_dir/host
sed -i 's#$(STAGING_DIR_HOST)/bin/upx#$(STAGING_DIR_HOSTPKG)/bin/upx#g' \
    package/community/helloworld/mihomo/Makefile package/community/helloworld/xray-core/Makefile
# rust: CI 预编译 LLVM 已过期(404)，改为源码编译 LLVM
sed -i 's/llvm.download-ci-llvm=true/llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# add luci-app-mosdns
rm -rf feeds/packages/net/v2ray-geodata
# 只保留 sbwml 的 mosdns：helloworld/官方 feeds 的 mosdns 自带 /etc/init.d/mosdns，
# 与 sbwml 的 luci-app-mosdns 文件冲突（25.12 的 apk 不允许覆盖）
rm -rf feeds/packages/net/mosdns package/feeds/packages/mosdns package/community/helloworld/mosdns
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata
