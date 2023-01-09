# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#........................................................................
# Purpose: Prepare CDH node for demo
#........................................................................
#Remove spaces and remove last line and append GCS connector config
sed -i '/^$/d' /etc/hadoop/conf/core-site.xml
sed -i '$ d' /etc/hadoop/conf/core-site.xml
#Add connector config
cat core-site-add.xml >>  /etc/hadoop/conf/core-site.xml
#Restart services
/usr/bin/docker-quickstart