content <- @"
NOTE: Files ""custom_config.nut"" and ""default_config.nut"" are obsolete and you can delete them.
NOTE: Before starting, make sure that the file extension display is enabled!!!
How to customize your configuration:
1. Create a directory named ""configs"".
2. Copy the file ""default_config_template.nut"" and paste it in the ""configs"" directory.
3. Rename the file you just pasted and the new name represents the name of configuration template.
The configuration template name can only contain letters, numbers, and underscores.
4. Enter the game, input the chat command ""/mtoz_cfg_load template_name"" to load the configuration template you want.
Example: ""/mtoz_cfg_load myconfig1"" will load the config file ""myconfig1.nut"" in directory ""configs"".
5. You can input the chat command ""/mtoz_cfg_autoload template_name"" to set a configuration template that will be loaded automatically every time the game starts.
(This command doesn't load the configuration template immediately.)
6. For step 5, if you don't want to input chat commands, just create a file named ""_autoload_.txt"" in directory ""configs"" and write the name of the configuration template(without file extension) you want in this file.

注意：文件“custom_config.nut”和“default_config.nut”已经被弃用，你可以删除它们。
注意：在开始之前，请确保启用文件扩展名显示！！！
如何自定义你的配置：
1. 创建一个名为“configs”的目录。
2. 复制文件“default_config_template.nut”并且将它粘贴在“configs”目录下。
3. 重命名你刚刚粘贴的文件，新的名称将会代表一个配置模板名称。
配置模板名称只能包含英文字母，数字和下划线。
4. 进入游戏，输入聊天指令“/mtoz_cfg_load template_name”来加载你想要的配置模板。
例子：“/mtoz_cfg_load myconfig1”会加载“configs”目录中的“myconfig1.nut”文件。
5. 你可以输入聊天指令“/mtoz_cfg_autoload template_name”来设置一个每次游戏开始都会自动加载的配置模板。（这条指令不会立即加载模板）
6. 对于步骤5，如果你不想输入聊天指令，那就在目录“configs”里创建一个名为“_autoload_.txt”的文件，在里面写入你想要自动加载的配置模板名称（不带文件后缀名）。
"