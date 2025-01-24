#import "conf.typ": conf
#import "functions.typ": *
#import "sections.typ": *

#let name = "Jaeho Cho"

#show: conf.with(
  author: name,
  paper: "us-letter",
  accent-color: "#000000",
  font: "Arial",
  font-size: 10pt,
  paragraph-leading: 0.57em,
  paragraph-spacing: 0.68em,
  section-heading-margin-top: 0.5em,
  section-heading-margin-bottom: 0.2em,
  border-margin: 0.3in,
)

#header(
  name: name,
  location: "New York, NY",
  phone: "+1 (201) 406-5974",
  email: "jaeho2025@gmail.com",
  linkedin: "jaeho-cho",
  website: "https://jaehho.github.io"
)

== Education

#edu(
  institution: "The Cooper Union for the Advancement of Science and Art",
  location: "New York City, NY",
  start-date: "Aug 2022",
  end-date: "May 2026",
  degree: "Bachelor of Engineering in Electrical Engineering, Bioengineering Minor",
)
- Half Tuition Scholarship | Myron Coe Scholarship | Full Tuition Scholarship 2025-2026
- Courses: Machine Learning, Digital Signal Processing, Communication Theory, Hardware Design, Electronics, Data Structures & Algorithms, Computer Architecture, Linear Algebra, Ordinary & Partial Differential Equations, Probability


== Work Experience

#work(
  position: "Data and AI Intern",
  details: "Hanwha TotalEnergies Petrochemical",
  company: "PWC",
  location: "Seoul, South Korea",
  start-date: "May 2024",
  end-date: "Aug 2024",
)
- Developed and optimized advanced time-series forecasting models using GluonTS, Chronos, and Darts to generate actionable price predictions for flagship petrochemical products, enabling data-driven decision-making.
- Refactored backend data pipelines in Django, transitioning from MongoDB to ClickHouse and improving performance.
- Built a web backend for business analysts, automating the aggregation of news and articles via APIs and integrating LLM-driven sentiment analysis with aforementioned forecasting models to enhance market insights.

#work(
  position: "Teacher Assistant",
  details: "Design and Drawing",
  company: "The Cooper Union",
  location: "New York, NY",
  start-date: "Jun 2023",
  end-date: "Aug 2023",
)
- Taught 24 high school students the fundamentals of engineering design, circuit design, Arduino and Onshape CAD.
- Led workshops on Arduinos and circuit design, culminating in students building 3D printed 4-DoF robotic arms.


== Extracurricular Activities

#extracurricular(
  position: "Founder/President",
  details: "The Pre-Medical & Pre-Dental Society",
  company: "The Cooper Union",
  location: "New York, NY",
  start-date: "Sep 2024",
  end-date: "Present",
)
- Established a support network for pre-medical and pre-dental students, bridging gaps in guidance at the Cooper Union.
- Coordinated events including a blood drive that attracted 40 donors and resulted in 37 blood donations, as well as alumni networking sessions that facilitated connections between students, medical school attendees, and professionals.

#extracurricular(
  position: "Project Lead",
  details: "Bioengineering Vertically Integrated Projects",
  company: "The Cooper Union",
  location: "New York, NY",
  start-date: "Sep 2022",
  end-date: "Present",
)
- Building open-source robotic arms for compliant human interaction, leveraging Mediapipe and OpenCV for real-time pose detection and integrating ROS2 for seamless control logic and interfacing with the OpenMANIPULATOR-X system.
- Simulated pose mimic systems in Gazebo, using MoveIt2 & ros2_control for collision detection and motion planning.
- Designed & fabricated a PCB in Altium for an eTextile sensor, presented at the 2024 ASTM International Exo Games.

#extracurricular(
  position: "Research Assistant",
  details: "Mechanical Exposure Study",
  company: "Mount Sinai",
  location: "New York, NY",
  start-date: "Feb 2024",
  end-date: "Aug 2024",
)
- Spearheaded the analysis of Xsens IMU data using MATLAB to quantify mechanical exposure in industrial workers.
- Implemented an automated pipeline for data collection, labeling, and analysis, streamlining the research process.

#extracurricular(
  position: "Shadow",
  details: "Dr. Steve Doh (Anesthesiologist)",
  company: "St. Joseph's Medical Center",
  location: "Yonkers, NY",
  start-date: "Jun 2023",
  end-date: "Jul 2023",
)
- Observed medical procedures, including endoscopies, laparoscopies, orthopedic surgeries, and open surgeries.
- Gained insight into the integration of advanced technology in surgeries, including the Da Vinci surgical system.


== #link("https://jaehho.github.io/portfolio/")[Projects]

#project(
  name: "Differential to Single-ended Amplifier",
  start-date: "Nov 2024",
  end-date: "Dec 2024",
)
- Designed schematic and layout using Virtuoso, with clean layout-versus-schematic (LVS) and design rule check (DRC).

#project(
  name: "32-bit Pipelined MIPS Processor",
  start-date: "Sep 2024",
  end-date: "Oct 2024",
)
- Designed, implemented and simulated the processor in Vivado, achieved full positive slack with a clock period of 14 ns.

#project(
  name: "Prosthetic Hand",
  start-date: "Aug 2021",
  end-date: "Sep 2023",
)
- Designed and built a 6-DoF myoelectric prosthetic hand with a friend who has a congenital left-hand anomaly (acheiria).


== Skills

- Programming: Python, MATLAB, Rust, C, C++, Verilog, VHDL, Git, Docker, Django, SQL
- Software: Virtuoso, LTspice, Altium, Vivado, ROS2, Gazebo, Blender, Onshape, Fusion360, Inventor
- Certification: NYS EMT, CPR
