import os
import sys
import argparse
import shutil
import subprocess
import time
import json
import re

RED = '\x1b[31m'
GREEN = '\x1b[32m'
YELLOW = '\x1b[33m'
BLUE = '\x1b[34m'
RESET = '\x1b[39m'

def Warn(*args):
    print(YELLOW, *args, RESET)

def Success(*args):
    print(GREEN, *args, RESET)

def Error(*args):
    print(RED, *args, RESET)
    sys.exit(1)

def Info(*args):
    print(BLUE, *args, RESET)

def main():
    
    # ===================== 参数 =====================
    current_dir = os.path.dirname(os.path.abspath(__file__))
    bat_path = os.path.join(current_dir, 'buildgmodshaders.bat')
    shaders_dir = os.path.join(current_dir, 'src', 'shaders')
    hlsl_dir = os.path.join(shaders_dir, 'hlsl')
    inc_dir = os.path.join(shaders_dir, 'inc')
    vcs_dir = os.path.join(shaders_dir, 'vcs')
    
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--sdk-path',
        type=str,
        required=False,
        help='source sdk 2013 stdshaders 目录路径',
        default="G:\\Tools\\source-sdk-2013-master\\src\\materialsystem\\stdshaders"
    )

    parser.add_argument(
        '--inc-construction-remove',
        type=bool,
        required=False,
        help='删除inc文件构造函数的参数',
        default=True
    )


    args = parser.parse_args()
    
    sdk_path = args.sdk_path

    if not os.path.isdir(sdk_path):
        Error(
            f'SDK路径不存在: {sdk_path}\n'
            '请检查路径是否正确'
        )

    # ===================== 拷贝hlsl_dir下的着色器到SDK=====================
    os.makedirs(hlsl_dir, exist_ok=True) 

    shaders = [
        file for file in os.listdir(hlsl_dir)
        if file.lower().endswith(('30.fxc', '30.hlsl'))
    ]


    for item in shaders:
        source_item = os.path.join(hlsl_dir, item)
        target_item = os.path.join(sdk_path, item)
        shutil.copy2(source_item, target_item)

    # ===================== 修改 stdshader 清单文件=====================
    # 只编译30 版本
    list_30_path = os.path.join(sdk_path, 'sdkshaders_dx9_30.txt')
    with open(list_30_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(shaders))


    # ===================== 开始编译=====================
    Info(
        '开始执行编译脚本\n'
        f'SDK:{sdk_path}\n'
        f'{len(shaders)}个\n',
        json.dumps(shaders, ensure_ascii=False, indent=2)
    )
  
    try:
        result = subprocess.run(
            bat_path,
            cwd=sdk_path,
            shell=True,  
            check=True,  
            capture_output=True,
            text=True,
            encoding='gbk'
        )
        
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
    except subprocess.CalledProcessError as e:
        Error(e.stderr, f'返回码: {e.returncode}')
        sys.exit(1)


    # ===================== 拷贝编译产物到inc_dir/vcs_dir=====================
    time.sleep(1)
    os.makedirs(vcs_dir, exist_ok=True)
    os.makedirs(inc_dir, exist_ok=True)

    sdk_vcs_dir = os.path.join(sdk_path, 'shaders', 'fxc')
    sdk_inc_dir = os.path.join(sdk_path, 'include')
   
    count = 0
    for file in shaders:
        shadername = os.path.splitext(file)[0]

        sdk_vcs_result = os.path.join(sdk_vcs_dir, f'{shadername}.vcs')
        vcs_result = os.path.join(vcs_dir, f'{shadername}.vcs')

        sdk_inc_result = os.path.join(sdk_inc_dir, f'{shadername}.inc')
        inc_result = os.path.join(inc_dir, f'{shadername}.inc')

        if os.path.exists(sdk_vcs_result):
            shutil.copy2(
                sdk_vcs_result, 
                vcs_result
            )

            os.chmod(sdk_inc_result, 0o777)
            shutil.copy2(sdk_inc_result, inc_result)

            # ---- 新增：自动处理 .inc 文件 ----
            try:
                with open(inc_result, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()

                # 匹配 ClassName_Static_Index( IShaderShadow* pShaderShadow, IMaterialVar** params )
                # 支持换行、空格、指针符号转义
                pattern = re.compile(
                    r'(\w+_Static_Index)\s*\(\s*'
                    r'IShaderShadow\s*\*\s*pShaderShadow\s*,\s*'
                    r'IMaterialVar\s*\*\*\s*params\s*\)',
                    re.DOTALL
                )
                content = pattern.sub(r'\1()', content)


                pattern = re.compile(
                    r'(\w+_Dynamic_Index)\s*\(\s*'
                    r'IShaderDynamicAPI\s*\*\s*pShaderAPI\s*'
                    r'\)',
                    re.DOTALL
                )
                content = pattern.sub(r'\1()', content)

                with open(inc_result, 'w', encoding='utf-8') as f:
                    f.write(content)

            except Exception as e:
                Warn(f'处理 {inc_result} 失败: {e}')
            # ---- 新增结束 ----

            count += 1
        else:
            Warn(f'{file} 编译失败')


    Success(
        f'编译完成\n'
        f'复制文件 {count} 个'
    )

    sys.exit(0)

if __name__ == '__main__':
    main()
