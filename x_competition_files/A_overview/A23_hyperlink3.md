The G4 machine series
The G4 machine series uses the AMD EPYC Turin CPU platform and features NVIDIA RTX PRO 6000 Blackwell Server Edition GPUs. This machine series offers significant improvements over the previous-generation G2 machine series, with considerably more GPU memory, increased GPU memory bandwidth, and higher networking bandwidth.

G4 instances have up to 384 vCPUs, 1,440 GB of memory, and 12 TiB of Titanium SSD disks attached. G4 instances also provide up to 400 Gbps of standard network performance.

This machine series is particularly intended for workloads such as NVIDIA Omniverse simulation workloads, graphics-intensive applications, video transcoding, and virtual desktops. The G4 machine series also provide a low-cost solution for performing single host inference and model tuning compared with A series machine types.

Instances that use the G4 machine type provide the following features:

GPU acceleration with NVIDIA RTX PRO 6000 Blackwell Server Edition GPUs: G4 instances automatically attach NVIDIA RTX PRO 6000 Blackwell Server Edition GPUs, which offer 96 GB GPU memory per GPU.

5th Generation AMD EPYC Turin CPU Platform: this platform offers up to 4.1 GHz sustained max boost frequency. For more information about this processor, see CPU platform.

Next generation graphics performance: the NVIDIA RTX PRO 6000 GPUs provide significant performance and feature upgrades over the NVIDIA L4 GPUs that are attached to the G2 machine series. Thesed upgrades are as follows:

5th-Generation Tensor Cores: these cores introduce support for FP4 precision and DLSS 4 Multi Frame Generation. By using these 5th Generation tensor cores, NVIDIA RTX PRO 6000 GPUs offers improved performance to accelerate tasks like local LLM development and content creation, compared to NVIDIA L4 GPUs.
4th-Generation RT Cores: these cores deliver up to twice the ray-tracing performance of the previous generation NVIDIA L4 GPUs, accelerating rendering for design and manufacturing workloads.
Core count: the NVIDIA RTX PRO 6000 GPU includes 24,064 CUDA cores, 752 5th-gen Tensor cores, and 188 4th-gen RT cores. This update represents a substantial increase over prior generations like the L4 GPU, which has 7,680 CUDA cores and 240 Tensor cores.
GPU sharing: there are a number of options that you can use to allow multiple workloads to access a single physical GPU. GPU sharing is useful for workloads that don't require the resources of a full GPU, helping you optimize costs. The following GPU sharing options are available for G4 instances:

Fractional GPU (vGPU) support (Preview): this feature allows a single physical GPU to be shared by multiple virtual machine (VM) instances. vGPUs provide multi-tenant security isolation because each vGPU is a separate VM instance. To use vGPUs, Compute Engine provides the following VM instance shapes: g4-standard-6 (1/8 GPU), g4-standard-12 (1/4 GPU), and g4-standard-24 (1/2 GPU).
Multi-Instance GPU (MIG): this feature allows a single GPU to be partitioned into up to four fully isolated instances on a single virtual machine. This option doesn't offer multi-tenant security isolation as all partitions belong to a single VM.
Peripheral Component Interconnect Express (PCIe) Gen 5 support: G4 instances supports PCI Express Gen 5, which improves the data transfer speed from CPU memory to GPU compared to PCIe Gen 3 used by G2 instances.

Disk support: G4 instances support Titanium SSD for fast scratch disks, which is useful for feeding data into GPUs while preventing I/O bottlenecks. For durable storage, you can attach Hyperdisk volumes.

G4 instances support attaching up to 12,000 GiB of Titanium SSD. For workloads that require durable block storage, G4 instances also support attaching up to 512 TiB of Hyperdisk. For more information about disk types, see Choose a disk type.

GPU Peer-to-Peer (P2P) communication: G4 instances support GPU P2P communication, enabling direct data transfer between GPUs within the same instance. This can significantly improve performance for multi-GPU workloads by reducing data transfer latency and freeing up CPU resources. For more information, see G4 GPU peer-to-peer (P2P) communication.

G4 machine types

G4 accelerator-optimized machine types use NVIDIA RTX PRO 6000 Blackwell Server Edition GPUs (nvidia-rtx-pro-6000) and are suitable for NVIDIA Omniverse simulation workloads, graphics-intensive applications, video transcoding, and virtual desktops. G4 machine types also provide a low-cost solution for performing single host inference and model tuning compared with A series machine types.

Note: To get started with G4 instances, see Create a G4 instance.
Attached NVIDIA RTX PRO 6000 GPUs
Machine type	vCPU count1	Instance memory (GB)	Maximum Titanium SSD supported (GiB)2	Physical NIC count	Maximum network bandwidth (Gbps)3	GPU count	GPU memory4
(GB GDDR7)
g4-standard-6	6	22	0	1	20	1/8	12
g4-standard-12	12	45	375	1	20	1/4	24
g4-standard-24	24	90	750	1	20	1/2	48
g4-standard-48	48	180	1,500	1	50	1	96
g4-standard-96	96	360	3,000	1	100	2	192
g4-standard-192	192	720	6,000	1	200	4	384
g4-standard-384	384	1,440	12,000	2	400	8	768
1A vCPU is implemented as a single hardware hyper-thread on one of the available CPU platforms.
2You can add Titanium SSD disks when creating a G4 instance. For the number of disks you can attach, see Machine types that require you to choose a number of Local SSD disks.
3Maximum egress bandwidth cannot exceed the number given. Actual egress bandwidth depends on the destination IP address and other factors. See Network bandwidth.
4GPU memory is the memory on a GPU device that can be used for temporary storage of data. It is separate from the instance's memory and is specifically designed to handle the higher bandwidth demands of your graphics-intensive workloads.

G4 limitations
You can only request capacity by using the supported consumption options for a G4 machine type.
You don't receive sustained use discounts and flexible committed use discounts for instances that use a G4 machine type.
You can only use a G4 machine type in certain regions and zones.
You can't use Persistent Disk (regional or zonal) on an instance that uses a G4 machine type.
The G4 machine type is only available on the AMD EPYC Turin 5th Generation platform.
You can't create Confidential VM instances that use a G4 machine type.
You can't create G4 instances on sole-tenant nodes.
You can't use Windows operating systems on g4-standard-384 instances.
You can't attach Hyperdisk ML disks that were created before February 4, 2026 to G4 machine types.
When creating G4 instances that have less than one GPU attached (fractional GPUs) (Preview), don't use the --no-service-account or --no-scopes flags. To authenticate NVIDIA vGPU drivers, Compute Engine must verify the VM's identity. This process requires that service accounts are enabled.
Supported disk types for G4 instances
G4 instances can use the following block storage types:

Hyperdisk Balanced (hyperdisk-balanced): this is the only disk type that is supported for the boot disk
Hyperdisk Balanced High Availability (hyperdisk-balanced-high-availability)
Hyperdisk Extreme (hyperdisk-extreme): this disk type is only supported on G4 instances that have two or more GPUs attached
Hyperdisk ML (hyperdisk-ml)
Hyperdisk Throughput (hyperdisk-throughput)
Titanium SSD: you can add Titanium SSD to instances created by using the G4 machine types.

Maximum number of disks per instance1
Machine types	All Hyperdisk	Hyperdisk Balanced	Hyperdisk Balanced High Availability	Hyperdisk Extreme	Hyperdisk ML	Hyperdisk Throughput	Titanium SSD
g4-standard-6	8	8	8	0	8	8	0
g4-standard-12	16	16	16	0	16	16	1
g4-standard-24	32	32	32	0	32	32	2
g4-standard-48	32	32	32	0	32	32	4
g4-standard-96	32	32	32	8	32	32	8
g4-standard-192	64	64	64	8	64	64	16
g4-standard-384	128	128	128	8	128	128	32
1Hyperdisk usage is charged separately from machine type pricing. For disk pricing, see Hyperdisk pricing.


You can attach a mixture of different Hyperdisk types to an instance, but the maximum total disk capacity (in TiB) across all disk types can't exceed 512 TiB for all Hyperdisks.

For details about the capacity limits, see Hyperdisk size and attachment limits.

GPU peer-to-peer (P2P) communication
G4 instances enhance multi-GPU workload performance by using direct GPU peer-to-peer (P2P) communication, which is supported only on machine types with two or more GPUs. This approach allows GPUs that attach to the same G4 instance to exchange data directly over the PCIe bus, bypassing the need to transfer data through the CPU's main memory. This direct path reduces latency, lowers CPU utilization, and increases the effective bandwidth between GPUs. P2P communication significantly accelerates multi-GPU applications such as machine learning (ML) training and high performance computing (HPC).

This feature typically requires no modifications to your application code. You only need to configure NCCL to use P2P. To configure NCCL, before you run your workloads, set the NCCL_P2P_LEVEL environment variable on your G4 instance based on the machine type:

For G4 instances with 2 or 4 GPUs (g4-standard-96, g4-standard-192): set NCCL_P2P_LEVEL=PHB
For G4 instances with 8 GPUs (g4-standard-384): set NCCL_P2P_LEVEL=SYS
Set the environment variable using one of the following options:

On the command line, run the appropriate export command (for example, export NCCL_P2P_LEVEL=SYS) in the shell session where you plan to run your application. To make this setting persistent, add this command to your shell's startup script (for example, ~/.bashrc).
Add the appropriate setting (for example, NCCL_P2P_LEVEL=SYS) to the NCCL configuration file located at /etc/nccl.conf.
Key benefits and performance
Accelerates multi-GPU workloads on G4 instances with two or more GPUs: provides faster runtimes for applications running on g4-standard-96, g4-standard-192, and g4-standard-384 machine types.
Provides high-bandwidth communication: enables high data transfer speeds between GPUs.
Improves NCCL performance: provides significant performance improvements for applications that use the NVIDIA Collective Communication Library (NCCL) when compared to communication that doesn't use P2P. Google's hypervisor securely isolates this P2P communication within your instances.

On four GPU instances (g4-standard-192), all GPUs are on a single NUMA node, allowing for the most efficient P2P communication. This can lead to performance improvements of up to 2.04x for collectives such as Allgather, Allreduce, and ReduceScatter.
On eight GPU instances (g4-standard-384), GPUs are distributed across two NUMA nodes. P2P communication is accelerated for traffic both within and between these nodes, with performance improvements of up to 2.19x for the same collectives.