# ===== Base Image =====
FROM osrf/ros:galactic-desktop

# ===== Timezone Configuration =====
ARG timezone=UTC
ENV TZ=${timezone}

# ===== User Setup =====
USER root
ARG USERNAME=ttbot
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# ===== Set up environment =====
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS2_WS=/home/${USERNAME}/ros2_ws
SHELL ["/bin/bash", "-c"]

# ===== System Configuration =====
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo \
        git \
        python3-dev \
        python3-lxml \
        iputils-ping \
        python3-pip \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ===== ROS 2 Dependencies =====
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ros-galactic-v4l2-camera \
        ros-galactic-joint-state-publisher \
        ros-galactic-robot-state-publisher \
        ros-galactic-gazebo-plugins \
        ros-galactic-rviz2 \
        ros-galactic-teleop-twist-keyboard \
        ros-galactic-teleop-twist-joy \
        ros-galactic-xacro \
        ros-galactic-urdf \
    && rm -rf /var/lib/apt/lists/*

# ======= Create User =======
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p ${ROS2_WS}/src /home/${USERNAME}/.config \
    && chown -R ${USER_UID}:${USER_GID} /home/${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && usermod --append --groups video ${USERNAME} \
    && usermod -a -G dialout ${USERNAME}

# ===== Python Configuration =====
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# ===== User Context + Workspace Setup =====
USER $USERNAME
WORKDIR ${ROS2_WS}
ENV PATH="$PATH:/home/${USERNAME}/.local/bin/"

# ===== Create and build workspace =====
# RUN git clone -b ros2-galactic http://github.com/rigbetellabs/tortoisebot.git src/tortoisebot
RUN git clone https://github.com/kailash197/cp23_ros2test_tortoisebot_waypoints.git src/tortoisebot_waypoints
COPY --chown=${USER_UID}:${USER_GID} ./tortoisebot ${ROS2_WS}/src/tortoisebot

# ===== Build =====
RUN . /opt/ros/galactic/setup.bash \
    && colcon build --symlink-install --cmake-args -DCMAKE_CXX_FLAGS="-w" \
    && source install/setup.bash \
    && echo "source /opt/ros/galactic/setup.bash" >> ~/.bashrc \
    && echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc

# ===== Environment Variables =====
ENV ROS_DISTRO=galactic
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ENV ROS_DOMAIN_ID=7
# COPY --chown=${USER_UID}:${USER_GID} ./tortoisebot_ros2_docker/gazebo/cyclonedds.xml /home/${USERNAME}/cyclonedds.xml
# ENV CYCLONEDDS_URI=file:///home/${USERNAME}/cyclonedds.xml

# ===== Entrypoint =====
COPY --chown=${USER_UID}:${USER_GID} ./ros2_ci/entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]