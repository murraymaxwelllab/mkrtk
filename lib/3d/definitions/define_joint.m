function j = define_joint
%JOINT produces the structure that defines a joint 
%
%              Tag: 'Joint_1'
%            Item1: 'Tibia'
%            Item2: 'Calcaneus'
%            Plane: []
%          Visible: 1
%             Axis: [35x3 double]
%            Angle: [35x1 double]
%            Point: [35x3 double]
%            Slide: [35x1 double]
%        JointAxis: [-0.9296 -0.1205 -0.3484]
%     InPlaneAngle: [35x1 double]

j = struct( 'Tag',{},...        % Name of the joint: 'Joint_1', 'Joint_2', etc
            'Item1',{},...      % Tag of first object (eg, 'Tibia', 'Femur')
            'Item2',{},...      % Tag of second object (eg, 'Calcaneus', 'Tibia')
            'Visible',{},...    % Visibility status: { [0] | 1 }
            'Axis',{},...       % N-by-3 series of helical axes
            'Angle',{},...      % N-by-1 series of angles of rotation around above helica axes
            'Point',{},...      % N-by-3 series of point locations for plotting origin of helical axis
            'Slide',{},...      % N-by-1 scalar of slide along axis
            'JointAxis',{},...  % 1-by-3 vector of "mean" joint axis
            'InPlaneAngle',{}); % N-by-1 series of component rotation around JointAxis ("in-plane rotation")