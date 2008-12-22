-- MySQL dump 10.11
--
-- Host: localhost    Database: desktop2
-- ------------------------------------------------------
-- Server version	5.0.51a-3ubuntu5.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `qo_dialogs`
--

DROP TABLE IF EXISTS `qo_dialogs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_dialogs` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(55) default NULL,
  `path` text,
  `type` varchar(15) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_dialogs`
--

LOCK TABLES `qo_dialogs` WRITE;
/*!40000 ALTER TABLE `qo_dialogs` DISABLE KEYS */;
/*!40000 ALTER TABLE `qo_dialogs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_files`
--

DROP TABLE IF EXISTS `qo_files`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_files` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(55) default NULL,
  `path` text,
  `type` varchar(15) default NULL,
  `active` set('false','true') NOT NULL default 'false',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=75 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_files`
--

LOCK TABLES `qo_files` WRITE;
/*!40000 ALTER TABLE `qo_files` DISABLE KEYS */;
INSERT INTO `qo_files` VALUES (51,'cookies.js','system/login/','javascript','true'),(52,'StartMenu.js','system/core/','javascript','true'),(53,'TaskBar.js','system/core/','javascript','true'),(54,'Desktop.js','system/core/','javascript','true'),(55,'App.js','system/core/','javascript','true'),(56,'Module.js','system/core/','javascript','true'),(57,'DesktopConfig.js','system/core/','javascript','true'),(58,'desktop.css','resources/css/','css','true'),(63,'Shortcut.js','system/core/','javascript','true'),(64,'NetworkStatus.js','system/core/network/','javascript','true'),(11,'Socket.js','lib/Sprocket','javascript','true'),(12,'Filter.js','lib/Sprocket/','javascript','true'),(13,'Line.js','lib/Sprocket/Filter/','javascript','true'),(14,'JSON.js','lib/Sprocket/Filter/','javascript','true'),(69,'sound-manager.css','system/core/sound/','css','true'),(70,'soundmanager2.js','system/core/sound/','javascript','true'),(71,'sound-manager.js','system/core/sound/','javascript','true'),(72,'ext-db.js','system/core/db/','javascript','true'),(73,'ext-ajax-db.js','system/core/db/','javascript','true'),(74,'gjsapi.js','system/core/gjsapi/','javascript','true'),(1,'PubSub.js','lib/Sprocket/PubSub.js','javascript','true'),(5,'Window.js','system/core/','javascript','true'),(59,'Sprocket.js','system/core/network/','javascript','true');
/*!40000 ALTER TABLE `qo_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_groups`
--

DROP TABLE IF EXISTS `qo_groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_groups` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(35) default NULL,
  `description` text,
  `active` set('false','true') NOT NULL default 'false',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_groups`
--

LOCK TABLES `qo_groups` WRITE;
/*!40000 ALTER TABLE `qo_groups` DISABLE KEYS */;
INSERT INTO `qo_groups` VALUES (1,'administrator','System administrator','true'),(2,'user','General user','true'),(3,'guest','Guest user','true');
/*!40000 ALTER TABLE `qo_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_groups_has_modules`
--

DROP TABLE IF EXISTS `qo_groups_has_modules`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_groups_has_modules` (
  `qo_groups_id` int(11) unsigned NOT NULL default '0',
  `qo_modules_id` int(11) unsigned NOT NULL default '0',
  `active` set('false','true') NOT NULL default 'false',
  PRIMARY KEY  (`qo_groups_id`,`qo_modules_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COMMENT='Stores what modules each group has access to';
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_groups_has_modules`
--

LOCK TABLES `qo_groups_has_modules` WRITE;
/*!40000 ALTER TABLE `qo_groups_has_modules` DISABLE KEYS */;
INSERT INTO `qo_groups_has_modules` VALUES (1,1,'true'),(1,2,'true'),(1,5,'true'),(1,4,'true'),(1,3,'true'),(1,6,'true'),(1,7,'true'),(1,8,'true'),(2,1,'true'),(2,2,'true'),(2,3,'true'),(2,4,'true'),(2,5,'true'),(2,6,'true'),(2,7,'true'),(2,8,'true'),(3,1,'true'),(3,2,'true'),(3,3,'true'),(3,4,'true'),(3,5,'true'),(3,6,'true'),(3,7,'true'),(3,8,'true'),(1,17,'true'),(2,17,'true'),(3,17,'true'),(1,18,'true'),(2,18,'true'),(3,18,'true'),(1,19,'true'),(2,19,'true'),(3,19,'true'),(3,20,'true'),(2,20,'true'),(1,20,'true'),(3,21,'true'),(2,21,'true'),(1,21,'true'),(1,22,'true'),(2,22,'true'),(3,22,'true'),(1,23,'true'),(2,23,'true'),(3,23,'true'),(1,24,'true'),(1,25,'true'),(2,25,'true'),(3,25,'true'),(1,26,'true'),(2,26,'true'),(3,26,'true'),(1,27,'true'),(2,27,'true'),(3,27,'true'),(1,28,'true'),(2,28,'true'),(3,28,'true'),(1,29,'true'),(2,29,'true'),(3,29,'true'),(1,30,'true'),(2,30,'true'),(3,30,'true'),(1,31,'true'),(1,32,'true'),(2,31,'true'),(3,31,'true');
/*!40000 ALTER TABLE `qo_groups_has_modules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_hulu_starred`
--

DROP TABLE IF EXISTS `qo_hulu_starred`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_hulu_starred` (
  `id` int(10) unsigned NOT NULL,
  `qo_members_id` int(11) unsigned NOT NULL,
  `record` text,
  PRIMARY KEY  (`id`,`qo_members_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_hulu_starred`
--

LOCK TABLES `qo_hulu_starred` WRITE;
/*!40000 ALTER TABLE `qo_hulu_starred` DISABLE KEYS */;
/*!40000 ALTER TABLE `qo_hulu_starred` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_launchers`
--

DROP TABLE IF EXISTS `qo_launchers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_launchers` (
  `id` int(2) unsigned NOT NULL auto_increment,
  `name` varchar(25) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_launchers`
--

LOCK TABLES `qo_launchers` WRITE;
/*!40000 ALTER TABLE `qo_launchers` DISABLE KEYS */;
INSERT INTO `qo_launchers` VALUES (1,'autorun'),(2,'contextmenu'),(3,'quickstart'),(4,'shortcut'),(5,'startmenu'),(6,'startmenutool');
/*!40000 ALTER TABLE `qo_launchers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_members`
--

DROP TABLE IF EXISTS `qo_members`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_members` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `first_name` varchar(25) default NULL,
  `last_name` varchar(35) default NULL,
  `email_address` varchar(55) default NULL,
  `active` set('false','true') NOT NULL default 'false',
  `validation_code` varchar(10) default NULL,
  `password` varchar(45) NOT NULL,
  `total_time` bigint(11) NOT NULL default '0',
  `logins` bigint(11) NOT NULL default '0',
  `last_access` timestamp NULL default NULL,
  `xmpp_password` varchar(50) default NULL,
  `xmpp_username` varchar(50) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `qo_members_uk1` (`email_address`),
  UNIQUE KEY `qo_members_uk2` (`email_address`,`password`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_members`
--

LOCK TABLES `qo_members` WRITE;
/*!40000 ALTER TABLE `qo_members` DISABLE KEYS */;
INSERT INTO `qo_members` VALUES (3,'Guest','','guest','true',NULL,'35675e68f4b5af7b995d9205ad0fc43842f16450',0,0,NULL,NULL,NULL),(4,'Admin','','admin','true',NULL,'d033e22ae348aeb5660fc2140aec35850c4da997',139986,3,'2008-12-22 19:20:32',NULL,NULL);
/*!40000 ALTER TABLE `qo_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_members_has_groups`
--

DROP TABLE IF EXISTS `qo_members_has_groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_members_has_groups` (
  `qo_members_id` int(11) unsigned NOT NULL default '0',
  `qo_groups_id` int(11) unsigned NOT NULL default '0',
  `active` set('false','true') NOT NULL default '',
  `admin_flag` set('false','true') NOT NULL default 'false' COMMENT 'true if member is the admin of this group',
  PRIMARY KEY  (`qo_members_id`,`qo_groups_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_members_has_groups`
--

LOCK TABLES `qo_members_has_groups` WRITE;
/*!40000 ALTER TABLE `qo_members_has_groups` DISABLE KEYS */;
INSERT INTO `qo_members_has_groups` VALUES (3,3,'true','false'),(4,1,'true','true');
/*!40000 ALTER TABLE `qo_members_has_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_modules`
--

DROP TABLE IF EXISTS `qo_modules`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_modules` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `moduleName` varchar(55) default NULL,
  `moduleType` varchar(35) default NULL,
  `moduleId` varchar(35) default NULL,
  `version` varchar(15) default NULL,
  `author` varchar(35) default NULL,
  `description` text,
  `path` text,
  `active` set('false','true') NOT NULL default 'false',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=33 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_modules`
--

LOCK TABLES `qo_modules` WRITE;
/*!40000 ALTER TABLE `qo_modules` DISABLE KEYS */;
INSERT INTO `qo_modules` VALUES (1,'QoDesk.QoPreferences','system','qo-preferences','1.0','Todd Murdock','A system application.  Allows users to change their desktop preferences.','system/modules/qo-preferences/','true'),(20,'QoDesk.Notepad','app','notepad','1.1','David Davis','Jot down notes.','system/modules/notepad/','true'),(21,'QoDesk.VideoPlayer','app','videoplayer','1.5','David Davis','Play videos.','system/modules/videoplayer/','true'),(22,'Ext.app.Registry','core','registry','1.0','David Davis','System Registry (AJAX)','system/core/registry/','true'),(23,'QoDesk.AboutCometDesktop','core','about-cometdesktop','1.0','David Davis','About Comet Desktop','system/modules/about-cometdesktop/','true'),(24,'QoDesk.AdminModules','system','admin-modules','1.1','David Davis','Modules Admin','system/modules/admin-modules/','true'),(25,'QoDesk.HuluPlayer','app','hulu-player','1.5','David Davis','Hulu TV','system/modules/hulu-player/','true'),(27,'QoDesk.FeedReader','app','feed-reader','1.0','Jack Slocum / David Davis','Read news feeds','system/modules/feed-reader/','true'),(29,'QoDesk.ToDoList','app','todo-list','1.0','Jack Slocum / David Davis','ToDo','system/modules/todo-list/','true');
/*!40000 ALTER TABLE `qo_modules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_modules_has_files`
--

DROP TABLE IF EXISTS `qo_modules_has_files`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_modules_has_files` (
  `qo_modules_id` int(11) unsigned NOT NULL default '0',
  `name` varchar(35) NOT NULL default '',
  `type` varchar(15) default NULL,
  PRIMARY KEY  (`qo_modules_id`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_modules_has_files`
--

LOCK TABLES `qo_modules_has_files` WRITE;
/*!40000 ALTER TABLE `qo_modules_has_files` DISABLE KEYS */;
INSERT INTO `qo_modules_has_files` VALUES (1,'preferences.css','css'),(1,'Preferences.js','javascript'),(20,'notepad.js','javascript'),(20,'notepad.css','css'),(21,'videoplayer.js','javascript'),(21,'videoplayer.css','css'),(22,'AJAXProvider.js','javascript'),(22,'registry.js','javascript'),(23,'about.js','javascript'),(23,'about.css','css'),(24,'admin-modules.js','javascript'),(24,'ux/drawer.js','javascript'),(24,'admin-modules.css','css'),(24,'ux/dataview.js','javascript'),(25,'hulu-player.css','css'),(25,'hulu-player.js','javascript'),(27,'tab-close-menu.js','javascript'),(27,'feed-reader.js','javascript'),(27,'feed-window.js','javascript'),(27,'feed-grid.js','javascript'),(27,'main-panel.js','javascript'),(27,'feed-panel.js','javascript'),(27,'feed-reader.css','css'),(29,'tasks.css','css'),(29,'classes.js','javascript'),(29,'tasks.js','javascript');
/*!40000 ALTER TABLE `qo_modules_has_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_modules_has_launchers`
--

DROP TABLE IF EXISTS `qo_modules_has_launchers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_modules_has_launchers` (
  `qo_members_id` int(11) unsigned NOT NULL default '0',
  `qo_groups_id` int(11) unsigned NOT NULL default '0',
  `qo_modules_id` int(11) unsigned NOT NULL default '0',
  `qo_launchers_id` int(10) unsigned NOT NULL default '0',
  `sort_order` int(5) unsigned NOT NULL default '0' COMMENT 'sort within each launcher',
  PRIMARY KEY  (`qo_members_id`,`qo_groups_id`,`qo_modules_id`,`qo_launchers_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_modules_has_launchers`
--

LOCK TABLES `qo_modules_has_launchers` WRITE;
/*!40000 ALTER TABLE `qo_modules_has_launchers` DISABLE KEYS */;
INSERT INTO `qo_modules_has_launchers` VALUES (0,0,1,2,10),(0,0,1,6,10),(0,0,23,2,30),(4,1,25,4,6),(6,2,22,1,0),(6,2,27,4,0),(6,2,25,4,2),(8,2,27,4,0),(0,0,23,6,60),(0,0,22,1,0),(3,3,25,3,4),(6,2,29,4,4),(0,0,20,5,50),(0,0,21,5,50),(3,3,21,4,10),(8,2,29,4,5),(0,1,24,4,0),(0,1,24,5,0),(0,0,25,5,0),(4,1,27,4,5),(0,0,27,5,0),(8,2,1,4,4),(3,3,27,4,9),(4,1,20,3,0),(4,1,29,4,2),(6,2,20,4,3),(5,2,27,4,0),(7,2,27,4,0),(7,2,25,4,1),(7,2,20,4,3),(7,2,1,4,4),(7,2,27,3,2),(7,2,20,3,0),(4,1,22,1,0),(4,1,21,4,3),(6,2,20,3,0),(0,0,29,5,0),(3,3,25,4,6),(3,3,21,1,8),(4,1,1,3,1),(4,1,20,4,0),(8,2,20,4,3),(8,2,25,4,1),(3,3,29,1,7),(8,2,22,1,0),(8,2,20,3,0),(8,2,27,3,1),(8,2,29,3,2),(9,2,1,4,7),(9,2,20,4,3),(9,2,25,4,1),(9,2,27,4,5),(9,2,29,4,4),(4,1,1,4,1),(3,3,27,3,0),(3,3,29,4,3),(3,3,1,4,2),(3,3,20,4,1),(3,3,25,1,4),(4,1,24,4,4),(3,3,27,1,2),(3,3,22,1,0);
/*!40000 ALTER TABLE `qo_modules_has_launchers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_notes`
--

DROP TABLE IF EXISTS `qo_notes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_notes` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `qo_members_id` int(11) unsigned NOT NULL,
  `note` text,
  PRIMARY KEY  (`id`,`qo_members_id`)
) ENGINE=MyISAM AUTO_INCREMENT=263 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_notes`
--

LOCK TABLES `qo_notes` WRITE;
/*!40000 ALTER TABLE `qo_notes` DISABLE KEYS */;
/*!40000 ALTER TABLE `qo_notes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_registry`
--

DROP TABLE IF EXISTS `qo_registry`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_registry` (
  `qo_members_id` int(11) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `val` text,
  PRIMARY KEY  (`qo_members_id`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_registry`
--

LOCK TABLES `qo_registry` WRITE;
/*!40000 ALTER TABLE `qo_registry` DISABLE KEYS */;
/*!40000 ALTER TABLE `qo_registry` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_sessions`
--

DROP TABLE IF EXISTS `qo_sessions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_sessions` (
  `id` varchar(128) NOT NULL default '' COMMENT 'a randomly generated id',
  `qo_members_id` int(11) unsigned NOT NULL default '0',
  `ip` varchar(16) default NULL,
  `date` datetime default NULL,
  `last_active` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `inactive` int(5) unsigned NOT NULL default '0',
  `useragent` varchar(255) NOT NULL default '',
  `session_duration` bigint(11) NOT NULL default '0',
  PRIMARY KEY  (`id`,`qo_members_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_sessions`
--

LOCK TABLES `qo_sessions` WRITE;
/*!40000 ALTER TABLE `qo_sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `qo_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_styles`
--

DROP TABLE IF EXISTS `qo_styles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_styles` (
  `qo_members_id` int(11) unsigned NOT NULL default '0',
  `qo_groups_id` int(11) unsigned NOT NULL default '0',
  `qo_themes_id` int(11) unsigned NOT NULL default '1',
  `qo_wallpapers_id` int(11) unsigned NOT NULL default '1',
  `backgroundcolor` varchar(6) NOT NULL default 'ffffff',
  `fontcolor` varchar(6) default NULL,
  `transparency` varchar(5) NOT NULL default 'false',
  `wallpaperposition` varchar(6) NOT NULL default 'center',
  PRIMARY KEY  (`qo_members_id`,`qo_groups_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_styles`
--

LOCK TABLES `qo_styles` WRITE;
/*!40000 ALTER TABLE `qo_styles` DISABLE KEYS */;
INSERT INTO `qo_styles` VALUES (3,3,1,3,'000000','C0C0C0','true','tile'),(4,1,2,10,'000000','FFFFFF','false','tile');
/*!40000 ALTER TABLE `qo_styles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_themes`
--

DROP TABLE IF EXISTS `qo_themes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_themes` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(25) default NULL,
  `path_to_thumbnail` varchar(255) default NULL,
  `path_to_file` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=18 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_themes`
--

LOCK TABLES `qo_themes` WRITE;
/*!40000 ALTER TABLE `qo_themes` DISABLE KEYS */;
INSERT INTO `qo_themes` VALUES (1,'Vista Blue','resources/themes/xtheme-vistablue/xtheme-vistablue.png','resources/themes/xtheme-vistablue/css/xtheme-vistablue.css'),(2,'Vista Black','resources/themes/xtheme-vistablack/xtheme-vistablack.png','resources/themes/xtheme-vistablack/css/xtheme-vistablack.css'),(3,'Vista Glass','resources/themes/xtheme-vistaglass/xtheme-vistaglass.png','resources/themes/xtheme-vistaglass/css/xtheme-vistaglass.css'),(4,'Slate','resources/themes/xtheme-slate/xtheme-slate.png','resources/themes/xtheme-slate/css/xtheme-slate.css'),(5,'Black','resources/themes/xtheme-black/xtheme-black.png','resources/themes/xtheme-black/css/xtheme-black.css'),(6,'DarkGray','resources/themes/xtheme-darkgray/xtheme-darkgray.png','resources/themes/xtheme-darkgray/css/xtheme-darkgray.css'),(7,'Gray Extend','resources/themes/xtheme-gray-extend/xtheme-gray-extend.png','resources/themes/xtheme-gray-extend/css/xtheme-gray-extend.css'),(8,'Indigo','resources/themes/xtheme-indigo/xtheme-indigo.png','resources/themes/xtheme-indigo/css/xtheme-indigo.css'),(9,'Midnight','resources/themes/xtheme-midnight/xtheme-midnight.png','resources/themes/xtheme-midnight/css/xtheme-midnight.css'),(10,'Olive','resources/themes/xtheme-olive/xtheme-olive.png','resources/themes/xtheme-olive/css/xtheme-olive.css'),(11,'Purple','resources/themes/xtheme-purple/xtheme-purple.png','resources/themes/xtheme-purple/css/xtheme-purple.css'),(12,'Pink','resources/themes/xtheme-pink/xtheme-pink.png','resources/themes/xtheme-pink/css/xtheme-pink.css');
/*!40000 ALTER TABLE `qo_themes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qo_wallpapers`
--

DROP TABLE IF EXISTS `qo_wallpapers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `qo_wallpapers` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(25) default NULL,
  `path_to_thumbnail` varchar(255) default NULL,
  `path_to_file` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `qo_wallpapers`
--

LOCK TABLES `qo_wallpapers` WRITE;
/*!40000 ALTER TABLE `qo_wallpapers` DISABLE KEYS */;
INSERT INTO `qo_wallpapers` VALUES (2,'Colorado Farm','resources/wallpapers/thumbnails/colorado-farm.jpg','resources/wallpapers/colorado-farm.jpg'),(3,'Curls On Green','resources/wallpapers/thumbnails/curls-on-green.jpg','resources/wallpapers/curls-on-green.jpg'),(4,'Emotion','resources/wallpapers/thumbnails/emotion.jpg','resources/wallpapers/emotion.jpg'),(5,'Eos','resources/wallpapers/thumbnails/eos.jpg','resources/wallpapers/eos.jpg'),(6,'Fields of Peace','resources/wallpapers/thumbnails/fields-of-peace.jpg','resources/wallpapers/fields-of-peace.jpg'),(7,'Fresh Morning','resources/wallpapers/thumbnails/fresh-morning.jpg','resources/wallpapers/fresh-morning.jpg'),(8,'Ladybuggin','resources/wallpapers/thumbnails/ladybuggin.jpg','resources/wallpapers/ladybuggin.jpg'),(9,'Summer','resources/wallpapers/thumbnails/summer.jpg','resources/wallpapers/summer.jpg'),(10,'Blue Swirl','resources/wallpapers/thumbnails/blue-swirl.jpg','resources/wallpapers/blue-swirl.jpg'),(11,'Blue Psychedelic','resources/wallpapers/thumbnails/blue-psychedelic.jpg','resources/wallpapers/blue-psychedelic.jpg'),(12,'Blue Curtain','resources/wallpapers/thumbnails/blue-curtain.jpg','resources/wallpapers/blue-curtain.jpg'),(1,'Blank','resources/wallpapers/thumbnails/blank.gif','resources/wallpapers/blank.gif'),(14,'Dark Day','resources/wallpapers/thumbnails/darkday.jpg','resources/wallpapers/darkday.jpg');
/*!40000 ALTER TABLE `qo_wallpapers` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2008-12-22 19:22:20
