
# NCL: 水汽通量与水汽通量散度

> Dongdong Kong, CUG

## DATA

- 数据来源于`ncep.reanalysis`：<https://downloads.psl.noaa.gov//Datasets/ncep.reanalysis/Dailies>

- 中国地图边界：<https://github.com/huangynj/NCL-Chinamap>


## Windows下搭建ncl运行环境

> ncl只能在linux like系统下运行，环境配置相对麻烦

1. 启动wsl功能

   控制面板 -> 程序和功能 -> 启用或关闭windows功能 -> 适用于Linux系统的Windows子系统。

   具体步骤详见知乎：<https://zhuanlan.zhihu.com/p/209032586>

2. 微软应用商店，安装ubuntu-20.04（稳定为第一需求，不要尝新猎奇）

3. 安装conda

4. 安装ncl

```bash
conda create -n ncl_stable -c conda-forge ncl
```

## How to run

```bash
ncl scripts/ex01_China_IVT.ncl
```

## Reference

1. <https://www.ncl.ucar.edu/Applications/wind.shtml>

2. <https://www.ncl.ucar.edu/Applications/Scripts/mfc_div_1.ncl>
