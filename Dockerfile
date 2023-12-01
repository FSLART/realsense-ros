FROM fslart/opencv-ros

ENV DEBIAN_FRONTEND=noninteractive

# update system
RUN apt update && apt upgrade -y

# install dependencies
RUN apt install git build-essential curl apt-transport-https libboost-dev libboost-python-dev -y
RUN apt install python3-rosdep python3-colcon-common-extensions python3-yaml python3-numpy python3-opencv -y

# install realsense sdk
RUN mkdir -p /etc/apt/keyrings && \
    curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | tee /etc/apt/keyrings/librealsense.pgp > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | tee /etc/apt/sources.list.d/librealsense.list && \
    apt update && \
    apt install librealsense2-dkms librealsense2-utils librealsense2-dev librealsense2-dbg -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# init rosdep
RUN rosdep update
RUN apt update

RUN apt install ros-humble-foxglove-bridge -y

# Create a workspace and copy the package
RUN mkdir -p /ros2_ws/src
COPY ./ /ros2_ws/src
WORKDIR /ros2_ws

# Install dependencies
RUN rosdep install -i --from-path src --rosdistro humble --skip-keys=librealsense2 -y

# Build the package
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && \
    cd /ros2_ws && \
    colcon build --parallel-workers 6"

CMD /bin/bash -c "source /opt/ros/humble/setup.bash && \
    cd /ros2_ws && \
    source install/local_setup.bash && \
    ros2 launch realsense2_camera all.launch"