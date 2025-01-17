#import "conf.typ": conf
#import "functions.typ": *
#import "sections.typ": *

#let name = "Jaeho Cho"
#show: conf.with(
  author: name,
  accent-color: "#000000",
  font: "New Computer Modern",
  paper: "us-letter",
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
  dates: dates-helper(start-date: "Aug 2022", end-date: "May 2026"),
  degree: "Bachelor of Engineering, Electrical Engineering, Bioengineering Minor",
)
- Half Tuition Scholarship | Myron Coe Scholarship | Full Tuition Scholarship 2025-2026
- "Courses: Machine Learning, Digital Signal Processing, Communication Theory, Hardware Design, Electronics, Data Structures & Algorithms, Computer Architecture, Linear Algebra, Ordinary & Partial Differential Equations, Probability"


== Work Experience

#work(
  title: "Data and AI Intern",
  location: "Seoul, South Korea",
  company: "PWC",
  dates: dates-helper(start-date: "May 2024", end-date: "Aug 2024"),
)
- Developed and optimized advanced time-series forecasting models using GluonTS, Chronos, and Darts to generate actionable price predictions for flagship petrochemical products, enabling data-driven decision-making.
- Refactored backend data pipelines, transitioning from MongoDB to ClickHouse and improving data flow efficiency.
- Built a web backend for business analysts, automating the aggregation of news and articles via APIs and integrating LLM-driven sentiment analysis with aforementioned forecasting models to enhance market insights.

#work(
  title: "Teacher Assistant - Design and Drawing",
  location: "New York, NY",
  company: "The Cooper Union",
  dates: dates-helper(start-date: "Jun 2023", end-date: "Aug 2023"),
)
- Taught 24 high school students the fundamentals of engineering design, circuit design, Arduino and Onshape CAD.
- Led workshops on Arduinos and circuit design, culminating in students building 3D printed 4-DoF robotic arms.


== Extracurricular Activities

#extracurriculars(
  activity: "Founder/President - The Pre-Medical & Pre-Dental Society",
  dates: dates-helper(start-date: "Sep 2024", end-date: "Present"),
)
- Established a support network for pre-medical/dental students, bridging gaps in guidance at the Cooper Union.
- Coordinated events including a blood drive that attracted 40 donors and resulted in 37 blood donations, as well as alumni networking sessions that facilitated connections between students, medical school attendees, and professionals.

#extracurriculars(
  activity: "Project Lead - Bioengineering Vertically Integrated Projects",
  dates: dates-helper(start-date: "Sep 2022", end-date: "Present"),
)
- Building open-source robotic arms for compliant human interaction, leveraging Mediapipe and OpenCV for real-time pose detection and integrating ROS2 for seamless control logic and interfacing with the OpenMANIPULATOR-X system.
- Simulated pose mimicking systems in Gazebo, using MoveIt2 & ros2_control for collision detection and motion planning.
- Designed & fabricated a custom PCB for an eTextile sensor, presented at the 2024 ASTM International Exo Games.

#extracurriculars(
  activity: "Research Assistant - Mechanical Exposure Study",
  dates: dates-helper(start-date: "Feb 2024", end-date: "Aug 2024"),
)
- Spearheaded the analysis of Xsens IMU data using MATLAB to quantify mechanical exposure in industrial workers.
- Implemented an automated pipeline for data collection, labeling, and analysis, streamlining the research process.

#extracurriculars(
  activity: "Shadow - Dr. Steve Doh (Anesthesiologist)",
  dates: dates-helper(start-date: "Jun 2023", end-date: "Jul 2023"),
)
- Observed medical procedures, including endoscopies, laparoscopies, orthopedic surgeries, and open surgeries.
- Gained insight into the integration of advanced technology in surgeries, including the Da Vinci surgical system.


== Skills

- *Programming*: Python, MATLAB, C, C++, Verilog, VHDL, Git, Docker, SQL, Django, React
- *Software*: Virtuoso, LTspice, Altium, Vivado, ROS2, Gazebo, Blender, Onshape, Fusion360, Inventor
- *Certification*: NYS EMT, CPR


// - name: Differential to Single-ended Amplifier
//   start_date: 2024-11
//   end_date: 2024-12
//   highlights:
//     - Designed schematic and layout using Virtuoso, performed layout-versus-schematic (LVS) and design rule check (DRC).
// - name: 32-bit Pipelined MIPS Processor
//   start_date: 2024-09
//   end_date: 2024-10
//   highlights:
//     - Designed, implemented and simulated the processor in Vivado, achieved full positive slack with a clock period of 14 ns.
// - name: Prosthetic Hand
//   start_date: 2021-08
//   end_date: 2023-09
//   highlights:
//     - Designed and built a 6-DoF myoelectric prosthetic hand with a friend who has a congenital left-hand anomaly (acheiria).