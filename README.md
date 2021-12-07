## MySQL数据库8.0规范

##### 建表规约
- [强制] 存储引擎`NGINE=InnoDB`，字符编码`CHARSET=utf8mb4`，字段索引类型`USING BTREE`
- [强制] 整形，如`int`、`bigint`、`tinyint`、`smallint`等，不用再指定长度
- [强制] 表达是与否概念的字段，必须使用is_xxx的方式命名，数据类型是unsigned tinyint（1:代表是 2:代表否）
``` 
说明：任何字段如果为非负数，必须是unsigned。
eg：`is_usable` tinyint unsigned DEFAULT 1 COMMENT '是否可用(1:是 2:否)'
``` 
- [强制] 表名、字段名必须是使用小写字母或数字，禁止出现数字开头，禁止两个下划线中间只出现数字，数据库字段名的修改代价很大，所以字段名称需要慎重考虑。
``` 
正例：uc_parent，level_name3
反例：UcParent，evel_3_name
``` 
- [强制] 表名使用单数名词。
``` 
说明：表名表示表里面的实体内容，所以采用单数
eg：system_user，system_merchant
``` 
- [强制] 禁用保留字，如desc、range、match、delayed等，请参考 MySQL官方保留字，参考：https://dev.mysql.com/doc/refman/5.7/en/keywords.html
- [强制] 索引命名规则：索引前缀 + 字段名
``` 
主键索引：pk_，eg：PRIMARY KEY (`id`) USING BTREE
唯一索引：uk_，eg：UNIQUE KEY `uk_brand_code` (`code`,`brand_id`) USING BTREE
普通索引：idx_，eg：KEY `idx_merchant_id` (`merchant_id`) USING BTREE
``` 
- [强制] 小数类型为decimal，禁止使用float和double
``` 
说明：float和double在存储的时候，存在精度损失的问题，在进行值比较时很可能得到不正确的结果。如果存储的数据范围超过decimal的范围，建议将数据拆成整数和小数分开存储。
``` 
- [强制] 如果存储的字符串长度几乎相等，使用char定长字符串类型，如`phone char(11) DEFAULT NULL COMMENT '家长电话'`
- [强制] `varchar`是可变长字符串，不预先分配存储空间，长度不要超过5000，如果存储长度大于此值，定义字段类型为`text`
- [强制] 新建表必备字段
``` 
id bigint unsigned NOT NULL COMMENT '主键ID'
app_id bigint unsigned NOT NULL COMMENT '应用ID'
merchant_id bigint unsigned NOT NULL COMMENT '商家ID'
is_delete tinyint unsigned NOT NULL DEFAULT '2' COMMENT '是否删除(1:是 2:否)'
creator_id bigint unsigned NOT NULL COMMENT '创建人ID'
created datetime NOT NULL COMMENT '创建时间'
modifier_id bigint unsigned NOT NULL COMMENT '修改人ID'
modified datetime NOT NULL COMMENT '修改时间'
``` 
- [强制] 如果修改字段含义或对字段表示的状态追加时，需要及时更新字段注释。
- [强制] 注释使用英文括号，英文冒号，用1个空格分割
``` 
eg：是否可用(1:是 2:否)
eg：卡类型(DC=借记 CC=贷记-信用卡 PB=存折 OC=其他)
``` 
- [强制] 字段允许为空的情况下，必须设置默认值为空字符串
``` 
`stu_name` varchar(20) DEFAULT '' COMMENT '学员姓名'
``` 
- [推荐] 字段允许适当冗余，以提高性能，但是必须考虑数据同步的情况。
``` 
冗余字段应遵循：
不是频繁修改的字段
不是varchar超长字段
正例：商品类目名称使用频率高，字段长度短，名称基本一成不变，可在相关联的表中冗余存储类目名称，避免关联查询。
``` 
- [推荐] 合适的字符存储长度，不但节约数据库表空间、节约索引存储，更重要的是提升检索速度。
``` 
正例：人的年龄用unsigned tinyint（表示范围0-255，人的寿命不会超过255岁）；海龟就必须是smallint，但如果是太阳的年龄，就必须是int；如果是所有恒星的年龄都加起来，那么就必须使用bigint。
``` 
- [推荐] 设计表遵循数据库的三范式
``` 
说明：
第1范式：列不可再分
第2范式：属性完全依赖于主键，满足第1范式才能满足第2范式，数据库表中的每个实例或行必须可以被惟一区分，为实现区分通常需要为表加上一个列，以存储各个实例的惟一标识，这个惟一属性列被称为主键。
第3范式：属性不依赖于其它非主属性，属性直接依赖于主键
``` 

##### 索引规约
- [强制] 业务上具有唯一特性的字段，即使是组合字段，也必须建成唯一索引。
``` 
说明：不要以为唯一索引影响了insert速度，这个速度损耗可以忽略，但提高查找速度是明显的；另外，即使在应用层做了非常完善的校验和控制，只要没有唯一索引，根据墨菲定律，必然有脏数据产生。
``` 
- [推荐] 索引顺序要和表里的字段顺序保持一致。
``` 
说明：虽然MySQL优化器会按自动做优化，条件按建表顺序有助于业务字段递进理解
``` 
- [推荐] 超过5个表禁止join，需要join的字段，数据类型保持绝对一致，多表关联查询时，保证被关联的字段需要有索引。
``` 
说明：即使双表join也要注意表索引、SQL性能。
``` 
- [推荐] 如果有order by的场景，请注意利用索引的有序性。order by最后的字段是组合索引的一部分，并且放在索引组合顺序的最后，避免出现file_sort的情况，影响查询性能。
``` 
正例：where a=? and b=? order by c；索引：a_b_c
反例：索引中有范围查找，那么索引有序性无法利用，如：where a > 10 order by b; 索引a_b无法排序。
``` 
- [推荐] 利用覆盖索引来进行查询操作，来避免回表操作。
``` 
说明：如果一本书需要知道第11章是什么标题，会翻开第11章对应的那一页吗？目录浏览一下就好，这个目录就是起到覆盖索引的作用。
扩展：
覆盖索引：减少回表，回到主键索引树搜索的过程，称为回表。查询结果是索引的字段或者主键就不用回表
最左前缀：联合索引的最左 N 个字段，也可以是字符串索引的最左 M 个字符
联合索引：按顺序检索，以最左原则进行 where 检索，比如：索引为(age, name)的情况，对于（age = 18 AND name = 'wuming'）或者（age = 18）都能利用索引，但（name = 'wuming'）不会使用索引
索引下推（MySQL 5.6 之后）：对查询条件过滤后回表
``` 
- [推荐] SQL性能优化的目标：至少要达到range级别，要求是ref级别，如果可以是consts最好。
``` 
说明：指的是EXPLAIN SQL语句结果集的type字段
consts 单表中最多只有一个匹配行（主键或者唯一索引），在优化阶段即可读取到数据
ref 指的是使用普通的索引（normal index）
range 对索引进行范围检索
反例：explain表的结果，type=index，索引物理文件全扫描，速度非常慢，这个index级别比较range还低，与全表扫描是小巫见大巫。
``` 
- [推荐] 建组合索引的时候，区分度最高的在最左边。
``` 
正例：如果 where a=? and b=?，a列的几乎接近于唯一值，那么只需要单建idx_a索引即可
说明：存在非等号和等号混合判断条件时，在建索引时，请把等号条件的列前置。如：where a>? and b=? 那么即使 a的区分度更高，也必须把 b放在索引的最前列。
``` 
- [参考] 创建索引时避免有如下极端误解
``` 
误认为一个查询就需要建一个索引
误认为索引会消耗空间、严重拖慢更新和新增速度
误认为唯一索引一律需要在应用层通过“先查后插”方式解决
``` 

##### SQL规约
- [强制] 在表查询中，一律不要使用 * 作为查询的字段列表，需要哪些字段必须明确写明。
``` 
说明：
增加查询分析器解析成本
增减字段容易与resultMap配置不一致
正例：SELECT id,title,content,modified... FROM table
反例：SELECT * FROM table
``` 
- [强制] 更新数据表记录时，必须同时更新记录对应的modified字段值为当前时间。
- [强制] 不要写一个大而全的数据更新接口，不管是不是自己的目标更新字段，都进行更新
``` 
说明：数据库有5个字段，需要更新3个字段的时候不要把5个字段都更新，①易出错，②效率低，③binlog增加存储
``` 
- [参考] @Transactional事务不要滥用。事务会影响数据库的QPS，另外使用事务的地方需要考虑各方面的回滚方案，包括缓存回滚、搜索引擎回滚、消息补偿、统计修正等。
- [强制] 在代码中写分页查询逻辑时，若count为0应直接返回，避免执行后面的分页语句
- [强制] 不得使用外键与级联，一切外键概念必须在应用层解决。
``` 
说明：（概念解释）学生表中的student_id是主键，那么成绩表中的student_id则为外键。如果更新学生表中的student_id，同时触发成绩表中的 student_id更新，则为级联更新。外键与级联更新适用于单机低并发，不适合分布式、高并发集群；级联更新是强阻塞，存在数据库更新风暴的风险；外键影响数据库的插入速度。
``` 
- [强制] 禁止使用存储过程，存储过程难以调试和扩展，更没有移植性。
- [强制] 数据订正时，删除和修改记录时，要先select，避免出现误删除，确认无误才能执行更新语句。
- [强制] WHERE 条件里注意隐式转换
``` 
SELECT `id`, `goods_id` FROM `gc_lessons` WHERE `is_finished` = 2 AND `is_usable` = 1 AND `is_delete` = 2 ORDER BY `created` ASC LIMIT 100 OFFSET 0;
执行耗时: 6.033 sec
SELECT `id`, `goods_id` FROM `gc_lessons` WHERE `is_finished` = '2' AND `is_usable` = '1' AND `is_delete` = '2' ORDER BY `created` ASC LIMIT 100 OFFSET 0;
执行耗时: 0.704 sec
``` 
- [强制] WHERE 条件里能用IN绝不允许使用FIND_IN_SET，性能差异巨大。
- [强制] TRUNCATE table比DELETE速度快，且使用的系统和事务日志资源少，但TRUNCATE无事务且不触发trigger，有可能造成事故，故不建议在开发代码中使用此语句。
``` 
说明：TRUNCATE table在功能上与不带WHERE子句的DELETE语句相同
``` 
- [推荐] in操作能避免则避免，若实在避免不了，需要仔细评估in后边的集合元素数量，控制在1000个之内
- [推荐] WHERE 条件里的字段顺序要和索引保持一致
