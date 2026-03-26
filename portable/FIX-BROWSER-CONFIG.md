# FIX-BROWSER-CONFIG.md

## Summary
This document outlines the fixes applied to address various issues in the project relating to browser configuration, including the Config Server 404 issue, cross-port API calls, and improvements to browser auto-launch functionality.

## Fixes Applied

### 1. Config Server 404 Issue
- **Description**: Resolved the 404 error encountered when trying to access the configuration server.
- **Solution**: Ensured the server is running correctly and that the endpoint URLs are properly configured in the application settings.

### 2. Cross-Port API Calls
- **Description**: Addressed issues related to making API calls across different ports.
- **Solution**: Implemented CORS (Cross-Origin Resource Sharing) configurations to facilitate secure cross-port communication between the client and the server.

### 3. Browser Auto-Launch Improvements
- **Description**: Improved the automatic launching of the browser after starting the server.
- **Solution**: Updated the browser launch configuration to ensure it opens to the correct URL and handles multiple instances effectively.

## Setup Instructions
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Tristanchen/meclaw.git
   cd meclaw
   ```
2. **Install Dependencies**:
   ```bash
   npm install
   ```
3. **Start the Application**:
   ```bash
   npm start
   ```
4. **Access Configuration**:
   Open your browser and navigate to [http://localhost:port/config](http://localhost:port/config) (Replace `port` with the actual port number).

5. **API Call Testing**:
   Ensure that you test the API calls across ports to verify that the CORS settings are functioning correctly.


## Conclusion
By following this documentation, you should be able to address the aforementioned issues effectively and set up the project without encountering the reported problems.