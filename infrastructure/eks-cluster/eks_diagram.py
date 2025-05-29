from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EKS, EC2, EC2AutoScaling
from diagrams.aws.network import VPC, InternetGateway, NATGateway, RouteTable, Endpoint, ElbNetworkLoadBalancer
from diagrams.aws.security import IAMRole
from diagrams.aws.network import PrivateSubnet, PublicSubnet
from diagrams.k8s.ecosystem import Helm
from diagrams.onprem.client import User

# Generate both PNG and SVG formats
output_formats = ["png", "svg"]

for fmt in output_formats:
    graph_attr = {
        "fontsize": "20",
        "bgcolor": "white",
        "rankdir": "TB",
        "pad": "0.5",
        "splines": "ortho",  # Use orthogonal lines for cleaner look
        "nodesep": "0.8",
        "ranksep": "1.0"
    }
    
    with Diagram("EKS Architecture", show=False, filename=f"eks_architecture_{fmt}", outformat=fmt, graph_attr=graph_attr):
        user = User("DevOps Engineer")
        
        with Cluster("AWS Region (ap-south-1)"):
            with Cluster("VPC (Workspace-specific CIDR)"):
                igw = InternetGateway("Internet Gateway")
                nat = NATGateway("NAT Gateway")
                s3_endpoint = Endpoint("S3 Endpoint")
                
                with Cluster("Public Subnets"):
                    public_subnet1 = PublicSubnet("Public Zone 1")
                    public_subnet2 = PublicSubnet("Public Zone 2")
                    bastion = EC2("Bastion Host")
                
                with Cluster("Private Subnets"):
                    private_subnet1 = PrivateSubnet("Private Zone 1")
                    private_subnet2 = PrivateSubnet("Private Zone 2")
                    
                    with Cluster("EKS Cluster (v1.32)"):
                        eks = EKS("EKS Control Plane")
                        
                        with Cluster("Node Group"):
                            asg = EC2AutoScaling("Auto Scaling Group")
                            node_group = EC2("SPOT t3a.medium")
                        
                        with Cluster("Add-ons"):
                            metrics = Helm("Metrics Server")
                            autoscaler = Helm("Cluster Autoscaler")
                            lbc = Helm("AWS LB Controller")
                            pod_identity = Helm("Pod Identity Agent")
                
                # Routing
                public_rt = RouteTable("Public Route Table")
                private_rt = RouteTable("Private Route Table")
                
                # IAM Roles
                eks_role = IAMRole("EKS Cluster Role")
                node_role = IAMRole("Node Role")
                bastion_role = IAMRole("Bastion Role")
                
                # Connections with labels for animation
                user >> Edge(label="SSH") >> bastion
                
                igw >> Edge(label="Internet Traffic") >> public_rt 
                public_rt >> Edge(label="Route") >> [public_subnet1, public_subnet2]
                
                public_subnet1 >> Edge(label="Outbound Traffic") >> nat 
                nat >> Edge(label="NAT") >> private_rt 
                private_rt >> Edge(label="Route") >> [private_subnet1, private_subnet2]
                
                private_rt >> Edge(label="S3 Access") >> s3_endpoint
                
                bastion >> Edge(label="kubectl") >> eks
                
                eks >> Edge(label="Control") >> [private_subnet1, private_subnet2]
                [private_subnet1, private_subnet2] >> Edge(label="Scale") >> asg 
                asg >> Edge(label="Launch") >> node_group
                
                eks_role >> Edge(label="Assume") >> eks
                node_role >> Edge(label="Assume") >> node_group
                bastion_role >> Edge(label="Assume") >> bastion
                
                eks >> Edge(label="Install") >> [metrics, autoscaler, lbc, pod_identity]

# Create an HTML file with animation
with open("animated_architecture.html", "w") as f:
    f.write("""<!DOCTYPE html>
<html>
<head>
    <title>Animated EKS Architecture</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { text-align: center; }
        .diagram { max-width: 100%; height: auto; }
        .controls { margin: 20px 0; }
        button { padding: 10px 15px; margin: 0 5px; cursor: pointer; }
        .description { margin-top: 20px; text-align: left; max-width: 800px; margin-left: auto; margin-right: auto; }
        .highlight { animation: pulse 2s infinite; }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        
        .path-animation {
            stroke-dasharray: 1000;
            stroke-dashoffset: 1000;
            animation: dash 3s linear forwards;
        }
        
        @keyframes dash {
            to {
                stroke-dashoffset: 0;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Animated EKS Architecture</h1>
        
        <div class="controls">
            <button onclick="showStep(1)">1. VPC & Networking</button>
            <button onclick="showStep(2)">2. EKS Control Plane</button>
            <button onclick="showStep(3)">3. Node Groups</button>
            <button onclick="showStep(4)">4. Add-ons</button>
            <button onclick="showStep(5)">5. Traffic Flow</button>
            <button onclick="resetAnimation()">Reset</button>
        </div>
        
        <div id="diagram-container">
            <object id="svg-object" data="eks_architecture_svg.svg" type="image/svg+xml" class="diagram"></object>
        </div>
        
        <div class="description" id="description">
            <h3>EKS Architecture Overview</h3>
            <p>Click the buttons above to explore different aspects of the architecture.</p>
        </div>
    </div>
    
    <script>
        // Wait for SVG to load
        document.getElementById('svg-object').addEventListener('load', function() {
            svgLoaded = true;
        });
        
        let svgLoaded = false;
        
        function getSVGDocument() {
            return document.getElementById('svg-object').contentDocument;
        }
        
        function resetAnimation() {
            if (!svgLoaded) return;
            
            const svgDoc = getSVGDocument();
            
            // Remove all highlights and animations
            const elements = svgDoc.querySelectorAll('*');
            elements.forEach(el => {
                el.classList.remove('highlight');
                el.classList.remove('path-animation');
            });
            
            document.getElementById('description').innerHTML = `
                <h3>EKS Architecture Overview</h3>
                <p>Click the buttons above to explore different aspects of the architecture.</p>
            `;
        }
        
        function showStep(step) {
            if (!svgLoaded) return;
            
            resetAnimation();
            const svgDoc = getSVGDocument();
            
            switch(step) {
                case 1:
                    // Highlight VPC and networking components
                    highlightElements(svgDoc, ['VPC', 'Internet Gateway', 'NAT Gateway', 'Public Zone', 'Private Zone', 'Route Table']);
                    document.getElementById('description').innerHTML = `
                        <h3>VPC & Networking</h3>
                        <p>The architecture uses a VPC with workspace-specific CIDR blocks:</p>
                        <ul>
                            <li>Dev: 10.0.0.0/16</li>
                            <li>Staging: 10.1.0.0/16</li>
                            <li>Prod: 10.2.0.0/16</li>
                        </ul>
                        <p>It includes public and private subnets across two availability zones, with an Internet Gateway for public internet access and a NAT Gateway for private subnet outbound traffic.</p>
                    `;
                    break;
                case 2:
                    // Highlight EKS control plane
                    highlightElements(svgDoc, ['EKS', 'Control Plane', 'Cluster']);
                    document.getElementById('description').innerHTML = `
                        <h3>EKS Control Plane</h3>
                        <p>The EKS Control Plane (v1.32) manages the Kubernetes cluster and includes:</p>
                        <ul>
                            <li>API Server with private and public endpoint access</li>
                            <li>Logging enabled for API, audit, authenticator, controller manager, and scheduler</li>
                            <li>IAM role with EKS Cluster Policy</li>
                        </ul>
                    `;
                    break;
                case 3:
                    // Highlight Node Groups
                    highlightElements(svgDoc, ['Node Group', 'Auto Scaling', 'SPOT', 't3a.medium']);
                    document.getElementById('description').innerHTML = `
                        <h3>Node Groups</h3>
                        <p>The EKS cluster uses a node group with the following characteristics:</p>
                        <ul>
                            <li>SPOT instances (t3a.medium) for cost optimization</li>
                            <li>Auto-scaling configuration (min: 2, max: 8, desired: 2)</li>
                            <li>Deployed across two private subnets for high availability</li>
                            <li>IAM role with necessary node policies</li>
                            <li>SSH access restricted to specific security groups</li>
                        </ul>
                    `;
                    break;
                case 4:
                    // Highlight Add-ons
                    highlightElements(svgDoc, ['Add-ons', 'Metrics Server', 'Cluster Autoscaler', 'AWS LB Controller', 'Pod Identity']);
                    document.getElementById('description').innerHTML = `
                        <h3>EKS Add-ons</h3>
                        <p>The cluster includes several add-ons to enhance functionality:</p>
                        <ul>
                            <li>Pod Identity Agent (v1.2.0) for IAM roles for service accounts</li>
                            <li>Metrics Server (v3.12.1) for resource metrics</li>
                            <li>Cluster Autoscaler (v9.37.0) for automatic node scaling</li>
                            <li>AWS Load Balancer Controller (v1.7.2) for managing ALBs/NLBs</li>
                        </ul>
                    `;
                    break;
                case 5:
                    // Highlight traffic flow
                    animatePaths(svgDoc);
                    document.getElementById('description').innerHTML = `
                        <h3>Traffic Flow</h3>
                        <p>The architecture handles traffic as follows:</p>
                        <ul>
                            <li>External traffic enters through the Internet Gateway to public subnets</li>
                            <li>Bastion host in public subnet provides secure access to the EKS cluster</li>
                            <li>Private subnets access the internet via NAT Gateway</li>
                            <li>S3 access from private subnets uses the S3 Gateway Endpoint</li>
                            <li>EKS control plane manages nodes in private subnets</li>
                            <li>Load balancers in public subnets route traffic to services in private subnets</li>
                        </ul>
                    `;
                    break;
            }
        }
        
        function highlightElements(svgDoc, keywords) {
            const elements = svgDoc.querySelectorAll('text');
            elements.forEach(el => {
                const text = el.textContent;
                if (keywords.some(keyword => text.includes(keyword))) {
                    // Find the parent group and highlight it
                    let parent = el.parentElement;
                    while (parent && parent.tagName !== 'g') {
                        parent = parent.parentElement;
                    }
                    if (parent) {
                        parent.classList.add('highlight');
                    }
                }
            });
        }
        
        function animatePaths(svgDoc) {
            const paths = svgDoc.querySelectorAll('path');
            paths.forEach(path => {
                if (path.getAttribute('stroke') && path.getAttribute('stroke') !== 'none') {
                    path.classList.add('path-animation');
                }
            });
        }
    </script>
</body>
</html>
""")

print("Generated static diagram as eks_architecture.png")
print("Generated SVG version as eks_architecture_svg.svg")
print("Created animated HTML version as animated_architecture.html")