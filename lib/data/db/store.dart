import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models.dart';
import 'demo.dart';
class Store{
 Store(this.db);final Database db;
 static Future<Store> open() async{
 final db=await openDatabase('${await getDatabasesPath()}/${demoMode?'cp_alarm_demo':'cp_alarm'}.db',version:3,onCreate:(db,v)async{
 await db.execute('CREATE TABLE settings(k TEXT PRIMARY KEY,v TEXT NOT NULL)');
 await db.execute('CREATE TABLE entries(id TEXT PRIMARY KEY,v TEXT NOT NULL)');
 await db.execute('CREATE TABLE accounts(p TEXT PRIMARY KEY,u TEXT NOT NULL,cursor INTEGER NOT NULL DEFAULT 0,last INTEGER,error TEXT)');
 await db.execute('CREATE TABLE submissions(p TEXT,id TEXT,v TEXT NOT NULL,PRIMARY KEY(p,id))');
 await db.execute('CREATE TABLE ratings(p TEXT,t INTEGER,v INTEGER NOT NULL,PRIMARY KEY(p,t))');
 await db.execute('CREATE TABLE contests(p TEXT,id TEXT,title TEXT,t INTEGER,d INTEGER,PRIMARY KEY(p,id))');
 await migrate2(db);await migrate3(db);
 },onUpgrade:(db,a,b)async{if(a<2)await migrate2(db);if(a<3)await migrate3(db);});await seedDemo(db); if((await db.query('settings',where:'k=?',whereArgs:['goals'])).isEmpty){await db.insert('settings',{'k':'goals','v':'[30,10,4]'});}return Store(db);
 }
 static Future<void> migrate3(DatabaseExecutor d)=>d.execute('CREATE TABLE solved(p TEXT,q TEXT,PRIMARY KEY(p,q))');
 static Future<void> migrate2(DatabaseExecutor d)async{
 await d.execute('ALTER TABLE accounts ADD COLUMN retry INTEGER NOT NULL DEFAULT 0');
 await d.execute('ALTER TABLE accounts ADD COLUMN failures INTEGER NOT NULL DEFAULT 0');
 await d.execute('CREATE INDEX contests_time ON contests(t)');
 }
 Future<void> put(String key,dynamic v)=>db.insert('settings',{'k':key,'v':jsonEncode(v)},conflictAlgorithm:ConflictAlgorithm.replace);
 Future<void> save(Entry e)=>db.insert('entries',{'id':e.id,'v':jsonEncode(e.json)},conflictAlgorithm:ConflictAlgorithm.replace);
 Future<void> remove(String id)=>db.delete('entries',where:'id=?',whereArgs:[id]);
 Future<void> unlink(String p)=>db.transaction((tx) async{
 for(final table in ['accounts','submissions','ratings','contests','solved']){await tx.delete(table,where:'p=?',whereArgs:[p]);}
 });
}
