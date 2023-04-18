#include <linux/init.h>
#include <linux/module.h>
#include <linux/printk.h>
#include <linux/kernel.h>
#include <linux/utsname.h>

#include "mod_xyz_defs.h"

static int __init mod_xyz_init(void)
{
	printk(KERN_INFO "Loading module mod_xyz ...\n");

	pr_alert("%s mod_xyz %s: %s\n",
		utsname()->sysname,
		utsname()->release,
		utsname()->version
	);

	return 0;
}

static void __exit mod_xyz_exit(void)
{
	pr_alert("exit mod_xyz driver\n");
}

module_init(mod_xyz_init);
module_exit(mod_xyz_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Linux Kernel Module mod_xyz");
MODULE_AUTHOR("2023 @Nuvoton");

