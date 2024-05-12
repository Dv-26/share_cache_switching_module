
该模块的总体可大致分为:输入模块，交换模块和输出模块三各部分。其中输入模块负责数据包解析，校验数据生成。交换模块为该模块的核心部分，负责数据的转发分类，中sram的的存储控制也由该模块实现。输出模块负责数据的调度管理以及校验。

### **voq**
为了实现内存回收以及多端口之间的动态存储。我们采用虚拟输出队列的方式来对单片sram进行管理，将没块sram按照端口数划分为16块区域，并每个区域的读写遵循先进先出的方式  
#### 端口和功能介绍

voq的各个输入端口和输出端口如下

- 写入控制端口
    - ` wr_data ` ：待写入的数据。
    - ` wr_sel ` ：选择写入的队列。
    - ` wr_vaild `：写入有效端，当信号有效时，在时钟上升沿将`wr_data`的数据写入`wr_sel`选择的队列中。
- 写入控制端口
    - ` rd_data ` ：读出的数据数据输出。
    - ` rd_sel ` ：选择读出的队列。
    - ` rd_vaild `：读出有效端，当信号有效时，在时钟上升沿将输出指定队列的数据。
- 其他端口
    - `full` ：满信号，当voq的存储空间写满时，该信号输出1
    - `alm_ost_full` ：当存储空间低于设定阈值时，该信号输出1
    - `empty`: 空信号，共16个代表16个队列，当第N个队列空时，第N位输出高1
    - `space`: 输出voq的有效存储空间

从使用上看，如图所示，`wr_sel`和`rd_sel`分别为数据分配器和数据选择器的选择端。从多个队列中选择单个，并且这些队列的存储都在一块sram上并且每个队列之间的存储空间是动态共享的。因此该模块只有一个full信号，而有多个empty信号。
![voq](/home/dv/verilog/switching_unit/draw/voq.png)

#### 模块的内部接口        

voq的内部结构分为三个部分，**分别为sram**、**多通道fifo**、**空闲地址(指针)队列**。sram为本模块要管理的sram，为双口ram。直接连接输入数据`rd_data`以及输出数据`wr_data`。空闲指针队列为普通的同步fifo模块，队列存储的数据为sram空闲即可利用空间的地址。初始化时空闲地址队列为满，代表全部空间未被利用。多通道fifo在使用上和voq一致，即从多个队列中选择单个队列进行读和写，它存储的数据是voq各个队列的地址，同时也是sram中有数据存储的非空闲地址。但是多端口fifo模块队列之间的存储并不是动态共享的，而是静态分配的。

voq实现多队列共享存储以及内存回收的原理如下。如图所示
![voq结构图](/home/dv/verilog/switching_unit/draw/voq结构图.png)
空闲地址队列的读数据输出端口`rd_out`分别接往sram的写地址`wr_addr`以及多端口fifo的写输入`wr_in`。voq模块的`wr_sel`接内部多端口fifo的`wr_sel`,`rd_sel`接多端口fifo的`rd_sel`。voq的`wr_vaild`内部连接多通道fifo的`wr_vaild`以及空闲队列的`rd_vaild`。`rd_vaild`内部连接多通道fifo的`rd_vaild`以及空闲地址队列的`wr_vaild`。  
当voq写如一个数据时，写入的数据存入空闲地址队列输出的地址，同时该地址写写入对应选择队列的在多通道fifo中的队列，即该队列的地址队列。当数据写入后空闲地址队列输出下个个空闲的地址。同理，当voq读出一个数据时，读出多端口fifo的输出地址所指向的空间，同时输入空闲地址队列。进而实现在单片sam中内存回收和多队列共享存储。  
空闲地址的空信号即为voq模块的满信号，而多端口fifo每个队列的空信号即为，voq模块每个端口的空信号。

### sram管理控制

通过把当块sram封装成voq，做到了单块sram内的内存回收以及动态共享存储。现在目标是将这种动态共享的性质扩展到多片sram所构成的存储空间。为了做到这一点，可以让数据均匀得存储到每一个voq中，并且每一个voq中各个队列所占用空间的比例也相同。当实现上面这种情况，就把单片sram的共享缓存特性扩展到32块sram，下面来解释一下这一点。  
所谓动态共享存储就是按照16个端口，将存储空间划分为16个可以动态调整的区域。并且这16个区域所占的空间之和不超过总的存储空间。如果每个空间再均等地给每块sram划分一样的空间，并且每块sram中16个区域划分的空间是动态存储的话。那么就相当于多块sram16个区域动态存储。

从输入模块输出到交换模块的端口

