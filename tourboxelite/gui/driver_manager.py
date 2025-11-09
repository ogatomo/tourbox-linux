#!/usr/bin/env python3
"""Driver service management for TourBox Elite

Handles starting, stopping, and checking status of the systemd service.
"""

import subprocess
import logging
from typing import Tuple

logger = logging.getLogger(__name__)


class DriverManager:
    """Manages the TourBox Elite driver systemd service"""

    SERVICE_NAME = "tourbox"

    @staticmethod
    def stop_driver() -> Tuple[bool, str]:
        """Stop the TourBox driver service

        Returns:
            Tuple of (success, message)
        """
        try:
            result = subprocess.run(
                ['systemctl', '--user', 'stop', DriverManager.SERVICE_NAME],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                logger.info("Driver stopped successfully")
                return True, "Driver stopped successfully"
            else:
                error_msg = f"Failed to stop driver: {result.stderr}"
                logger.error(error_msg)
                return False, error_msg

        except subprocess.TimeoutExpired:
            error_msg = "Timeout stopping driver"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Error stopping driver: {e}"
            logger.error(error_msg)
            return False, error_msg

    @staticmethod
    def start_driver() -> Tuple[bool, str]:
        """Start the TourBox driver service

        Returns:
            Tuple of (success, message)
        """
        try:
            result = subprocess.run(
                ['systemctl', '--user', 'start', DriverManager.SERVICE_NAME],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                logger.info("Driver started successfully")
                return True, "Driver started successfully"
            else:
                error_msg = f"Failed to start driver: {result.stderr}"
                logger.error(error_msg)
                return False, error_msg

        except subprocess.TimeoutExpired:
            error_msg = "Timeout starting driver"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Error starting driver: {e}"
            logger.error(error_msg)
            return False, error_msg

    @staticmethod
    def reload_driver() -> Tuple[bool, str]:
        """Apply new configuration to the TourBox driver via SIGHUP

        Sends SIGHUP signal to the driver process to reload its configuration
        without restarting the service.

        Returns:
            Tuple of (success, message)
        """
        try:
            # Use systemctl kill --signal=SIGHUP to send the signal
            result = subprocess.run(
                ['systemctl', '--user', 'kill', '--signal=SIGHUP', DriverManager.SERVICE_NAME],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0:
                logger.info("Configuration reload signal sent successfully")
                return True, "Configuration applied"
            else:
                error_msg = f"Failed to apply configuration: {result.stderr}"
                logger.error(error_msg)
                return False, error_msg

        except subprocess.TimeoutExpired:
            error_msg = "Timeout applying configuration"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Error applying configuration: {e}"
            logger.error(error_msg)
            return False, error_msg

    @staticmethod
    def restart_driver() -> Tuple[bool, str]:
        """Restart the TourBox driver service

        Returns:
            Tuple of (success, message)
        """
        try:
            result = subprocess.run(
                ['systemctl', '--user', 'restart', DriverManager.SERVICE_NAME],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                logger.info("Driver restarted successfully")
                return True, "Driver restarted successfully"
            else:
                error_msg = f"Failed to restart driver: {result.stderr}"
                logger.error(error_msg)
                return False, error_msg

        except subprocess.TimeoutExpired:
            error_msg = "Timeout restarting driver"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Error restarting driver: {e}"
            logger.error(error_msg)
            return False, error_msg

    @staticmethod
    def is_running() -> bool:
        """Check if the driver service is currently running

        Returns:
            True if running, False otherwise
        """
        try:
            result = subprocess.run(
                ['systemctl', '--user', 'is-active', DriverManager.SERVICE_NAME],
                capture_output=True,
                text=True,
                timeout=5
            )

            is_active = result.returncode == 0 and result.stdout.strip() == 'active'
            logger.debug(f"Driver running status: {is_active}")
            return is_active

        except Exception as e:
            logger.error(f"Error checking driver status: {e}")
            return False
